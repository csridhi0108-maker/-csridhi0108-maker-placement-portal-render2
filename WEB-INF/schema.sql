-- Campus Placement and Recruitment Drive Management System
-- PostgreSQL version of the Oracle 19c schema (13 tables, 2 triggers, 2 views, sample data).
-- Runs once, automatically, the first time the portal connects to an empty database.

CREATE TABLE Department (
    dept_id     NUMERIC PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL,
    dept_code   VARCHAR(10) UNIQUE
);

CREATE TABLE Student (
    student_id  NUMERIC PRIMARY KEY,
    name        VARCHAR(60) NOT NULL,
    dept_id     NUMERIC NOT NULL,
    email       VARCHAR(80) UNIQUE,
    CONSTRAINT fk_student_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

CREATE TABLE Academic_Record (
    record_id   NUMERIC PRIMARY KEY,
    student_id  NUMERIC NOT NULL UNIQUE,
    cgpa        NUMERIC(3,2) NOT NULL,
    backlogs    NUMERIC(2) DEFAULT 0 NOT NULL,
    CONSTRAINT fk_record_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT chk_cgpa CHECK (cgpa BETWEEN 0 AND 10),
    CONSTRAINT chk_backlogs CHECK (backlogs >= 0)
);

CREATE TABLE Skill (
    skill_id    NUMERIC PRIMARY KEY,
    skill_name  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Student_Skill (
    student_id  NUMERIC NOT NULL,
    skill_id    NUMERIC NOT NULL,
    CONSTRAINT pk_student_skill PRIMARY KEY (student_id, skill_id),
    CONSTRAINT fk_ss_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT fk_ss_skill FOREIGN KEY (skill_id) REFERENCES Skill(skill_id)
);

CREATE TABLE Company (
    company_id  NUMERIC PRIMARY KEY,
    name        VARCHAR(80) NOT NULL,
    sector      VARCHAR(50)
);

CREATE TABLE Job_Profile (
    profile_id  NUMERIC PRIMARY KEY,
    company_id  NUMERIC NOT NULL,
    role        VARCHAR(60) NOT NULL,
    package_lpa NUMERIC(5,2),
    CONSTRAINT fk_profile_company FOREIGN KEY (company_id) REFERENCES Company(company_id)
);

CREATE TABLE Drive (
    drive_id    NUMERIC PRIMARY KEY,
    profile_id  NUMERIC NOT NULL,
    drive_date  DATE NOT NULL,
    CONSTRAINT fk_drive_profile FOREIGN KEY (profile_id) REFERENCES Job_Profile(profile_id)
);

CREATE TABLE Eligibility_Criteria (
    drive_id        NUMERIC PRIMARY KEY,
    min_cgpa        NUMERIC(3,2) NOT NULL,
    max_backlogs    NUMERIC(2) DEFAULT 0,
    CONSTRAINT fk_elig_drive FOREIGN KEY (drive_id) REFERENCES Drive(drive_id),
    CONSTRAINT chk_min_cgpa CHECK (min_cgpa BETWEEN 0 AND 10)
);

CREATE TABLE Application (
    app_id      NUMERIC PRIMARY KEY,
    student_id  NUMERIC NOT NULL,
    drive_id    NUMERIC NOT NULL,
    applied_on  DATE DEFAULT CURRENT_DATE,
    CONSTRAINT fk_app_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT fk_app_drive FOREIGN KEY (drive_id) REFERENCES Drive(drive_id),
    CONSTRAINT uq_student_drive UNIQUE (student_id, drive_id)
);

CREATE TABLE Placement_Round (
    round_id    NUMERIC PRIMARY KEY,
    drive_id    NUMERIC NOT NULL,
    round_no    NUMERIC(2) NOT NULL,
    round_type  VARCHAR(30) NOT NULL,
    CONSTRAINT fk_round_drive FOREIGN KEY (drive_id) REFERENCES Drive(drive_id),
    CONSTRAINT uq_drive_roundno UNIQUE (drive_id, round_no)
);

CREATE TABLE Result (
    app_id      NUMERIC NOT NULL,
    round_id    NUMERIC NOT NULL,
    status      VARCHAR(10) NOT NULL,
    CONSTRAINT pk_result PRIMARY KEY (app_id, round_id),
    CONSTRAINT fk_result_app FOREIGN KEY (app_id) REFERENCES Application(app_id),
    CONSTRAINT fk_result_round FOREIGN KEY (round_id) REFERENCES Placement_Round(round_id),
    CONSTRAINT chk_status CHECK (status IN ('Pass', 'Fail'))
);

CREATE TABLE Offer (
    offer_id    NUMERIC PRIMARY KEY,
    app_id      NUMERIC NOT NULL UNIQUE,
    offer_date  DATE DEFAULT CURRENT_DATE,
    status      VARCHAR(10) DEFAULT 'Pending',
    CONSTRAINT fk_offer_app FOREIGN KEY (app_id) REFERENCES Application(app_id),
    CONSTRAINT chk_offer_status CHECK (status IN ('Pending', 'Accepted', 'Rejected'))
);

-- Trigger 1: eligibility is checked when a student applies (Oracle ORA-20001 -> E20001)
CREATE FUNCTION fn_check_eligibility() RETURNS trigger AS $$
DECLARE
    v_cgpa      NUMERIC;
    v_backlogs  NUMERIC;
    v_min_cgpa  NUMERIC;
    v_max_back  NUMERIC;
BEGIN
    SELECT cgpa, backlogs INTO v_cgpa, v_backlogs
      FROM Academic_Record WHERE student_id = NEW.student_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'E20001: No academic record found for this student.';
    END IF;
    SELECT min_cgpa, max_backlogs INTO v_min_cgpa, v_max_back
      FROM Eligibility_Criteria WHERE drive_id = NEW.drive_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'E20001: No eligibility criteria found for this drive.';
    END IF;
    IF v_cgpa < v_min_cgpa OR v_backlogs > v_max_back THEN
        RAISE EXCEPTION 'E20001: Student does not meet eligibility criteria for this drive.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_eligibility
BEFORE INSERT ON Application
FOR EACH ROW EXECUTE FUNCTION fn_check_eligibility();

-- Trigger 2: a round can be entered only after passing the previous round (ORA-20002/20003 -> E20002/E20003)
CREATE FUNCTION fn_check_round_sequence() RETURNS trigger AS $$
DECLARE
    v_round_no      NUMERIC;
    v_drive_id      NUMERIC;
    v_prev_round_id NUMERIC;
    v_prev_status   VARCHAR;
BEGIN
    SELECT round_no, drive_id INTO v_round_no, v_drive_id
      FROM Placement_Round WHERE round_id = NEW.round_id;

    IF v_round_no > 1 THEN
        SELECT round_id INTO v_prev_round_id
          FROM Placement_Round WHERE drive_id = v_drive_id AND round_no = v_round_no - 1;

        SELECT status INTO v_prev_status
          FROM Result WHERE app_id = NEW.app_id AND round_id = v_prev_round_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'E20003: Previous round result not found - student has not cleared the prior stage.';
        END IF;

        IF v_prev_status <> 'Pass' THEN
            RAISE EXCEPTION 'E20002: Cannot enter this round without passing the previous round.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_round_sequence
BEFORE INSERT ON Result
FOR EACH ROW EXECUTE FUNCTION fn_check_round_sequence();

-- Views used by the admin dashboard and the Reports page
CREATE VIEW vw_department_placement_stats AS
SELECT d.dept_name, COUNT(o.offer_id) AS offers_made
FROM Offer o
JOIN Application a ON o.app_id = a.app_id
JOIN Student s ON a.student_id = s.student_id
JOIN Department d ON s.dept_id = d.dept_id
GROUP BY d.dept_name;

CREATE VIEW vw_company_offer_stats AS
SELECT c.name AS company_name, jp.role, COUNT(o.offer_id) AS offers_made
FROM Offer o
JOIN Application a ON o.app_id = a.app_id
JOIN Drive dr ON a.drive_id = dr.drive_id
JOIN Job_Profile jp ON dr.profile_id = jp.profile_id
JOIN Company c ON jp.company_id = c.company_id
GROUP BY c.name, jp.role;

-- Sample data (demo copy; the submitted project uses the Oracle database)
INSERT INTO Department VALUES (1, 'Computer Science', 'CSE'), (2, 'Electronics', 'ECE'), (3, 'Mechanical', 'MECH');
INSERT INTO Student VALUES
 (101, 'Aditi Rao', 1, 'aditi.rao@example.com'),
 (102, 'Rahul Verma', 1, 'rahul.verma@example.com'),
 (103, 'Sneha Iyer', 2, 'sneha.iyer@example.com'),
 (104, 'Karthik Nair', 2, 'karthik.nair@example.com'),
 (105, 'Priya Menon', 3, 'priya.menon@example.com');
INSERT INTO Academic_Record VALUES
 (1, 101, 8.75, 0), (2, 102, 7.20, 1), (3, 103, 9.10, 0), (4, 104, 6.80, 2), (5, 105, 8.05, 0);
INSERT INTO Skill VALUES (1, 'Java'), (2, 'Python'), (3, 'SQL'), (4, 'Communication');
INSERT INTO Student_Skill VALUES (101, 1), (101, 3), (102, 2), (103, 3), (104, 4), (105, 2), (105, 4);
INSERT INTO Company VALUES (1, 'TechNova Solutions', 'IT Services'), (2, 'GreenGrid Energy', 'Renewable Energy'), (3, 'FinEdge Analytics', 'Fintech');
INSERT INTO Job_Profile VALUES (1, 1, 'Software Engineer', 8.50), (2, 2, 'Electrical Design Engineer', 6.75), (3, 3, 'Data Analyst', 7.20);
INSERT INTO Drive VALUES (1, 1, DATE '2026-10-15'), (2, 2, DATE '2026-10-20'), (3, 3, DATE '2026-10-25');
INSERT INTO Eligibility_Criteria VALUES (1, 7.00, 1), (2, 6.50, 2), (3, 8.00, 0);
INSERT INTO Placement_Round VALUES
 (1, 1, 1, 'Aptitude'), (2, 1, 2, 'Technical'), (3, 1, 3, 'HR'),
 (4, 2, 1, 'Aptitude'), (5, 2, 2, 'Technical'),
 (6, 3, 1, 'Aptitude'), (7, 3, 2, 'Technical');
INSERT INTO Application VALUES
 (1, 102, 1, DATE '2026-10-05'), (2, 103, 2, DATE '2026-10-06'),
 (3, 105, 3, DATE '2026-10-06'), (4, 101, 2, DATE '2026-10-07');
INSERT INTO Result VALUES
 (1, 1, 'Pass'), (1, 2, 'Pass'), (1, 3, 'Pass'),
 (2, 4, 'Pass'), (2, 5, 'Pass'),
 (3, 6, 'Pass'), (3, 7, 'Pass');
INSERT INTO Offer VALUES
 (1, 1, DATE '2026-10-10', 'Pending'),
 (2, 2, DATE '2026-10-10', 'Pending'),
 (3, 3, DATE '2026-10-10', 'Accepted');
