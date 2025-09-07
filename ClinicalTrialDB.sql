
CREATE DATABASE ClinicalTrialsDB;

USE ClinicalTrialsDB;

-- Create ClinicalTrials table
CREATE TABLE ClinicalTrials (
    TrialID INT IDENTITY NOT NULL PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL
);


-- Create PrincipalInvestigator table
CREATE TABLE PrincipalInvestigator (
    PrincipalInvestigatorID INT IDENTITY NOT NULL PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Experience INT 
);

-- Create TrialInvestigator table
CREATE TABLE TrialInvestigator (
    TrialID INT NOT NULL,
    PrincipalInvestigatorID INT NOT NULL,
    PRIMARY KEY (TrialID, PrincipalInvestigatorID),
    FOREIGN KEY (TrialID) REFERENCES ClinicalTrials(TrialID),
    FOREIGN KEY (PrincipalInvestigatorID) REFERENCES PrincipalInvestigator(PrincipalInvestigatorID)
);


-- Create Medication table
CREATE TABLE Medication (
    MedicationID INT IDENTITY NOT NULL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Date DATETIME NOT NULL,
    TrialID INT NOT NULL,
    FOREIGN KEY (TrialID) REFERENCES ClinicalTrials(TrialID)
);

-- Create Dosage table
CREATE TABLE Dosage (
    DosageID INT IDENTITY NOT NULL PRIMARY KEY,
    DosageAmount INT NOT NULL,
    DosageUnit VARCHAR(20) NOT NULL,
    Frequency INT NOT NULL,
    RouteofAdministrationType VARCHAR(20) NOT NULL,
    MedicationID INT NOT NULL,
    FOREIGN KEY (MedicationID) REFERENCES Medication(MedicationID)
);


-- Function to check the frequency count for route of administration
CREATE FUNCTION CheckRoute(@DosageID int)
RETURNS SMALLINT
AS
BEGIN
    DECLARE @Count SMALLINT=0;
    SELECT @Count=COUNT(Frequency)
    FROM Dosage
    WHERE DosageID=@DosageID AND RouteofAdministrationType in ('intravenous','intramuscular');
    RETURN @Count;
END;


-- Adding the Table level CHECK Constraint
ALTER TABLE Dosage ADD CONSTRAINT RouteCheck
CHECK (dbo.CheckRoute(DosageID) <= 1);


-- Create ClinicalSite table
CREATE TABLE ClinicalSite (
    SiteID BIGINT IDENTITY NOT NULL PRIMARY KEY,
    SiteName VARCHAR(255),
    Location VARCHAR(50)
);

-- Create Participant table
CREATE TABLE Participant (
    ParticipantID INT IDENTITY NOT NULL PRIMARY KEY,
    TrialID INT NOT NULL,
    MedicalHistoryID INT NOT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    ConsentStatus VARCHAR(1),
    ContactInformation BIGINT,
    SiteID BIGINT NOT NULL,
    DateOfBirth DATE NOT NULL,
    FOREIGN KEY (TrialID) REFERENCES ClinicalTrials(TrialID),
    FOREIGN KEY (SiteID) REFERENCES ClinicalSite(SiteID)
);

-- Function to calculate age of a Participant
CREATE FUNCTION CalculateAge (@ParticipantID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;

    SELECT @Age = DATEDIFF(YEAR, DateOfBirth, GETDATE())
    FROM Participant
    WHERE ParticipantID = @ParticipantID;

    RETURN @Age;
END;

-- Alter Table to add column age
ALTER TABLE Participant ADD age AS (dbo.CalculateAge(ParticipantID));



-- Create MedicalHistory table
CREATE TABLE MedicalHistory (
    ParticipantID INT NOT NULL,
    MedicalHistoryID INT IDENTITY NOT NULL PRIMARY KEY,
    PrimaryMedication VARCHAR(100),
    Surgery INT,
    RecurringPatient VARCHAR(1),
    FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID)
);

-- Create InformedConsentForm table
CREATE TABLE InformedConsentForm (
    ConsentFormID INT IDENTITY NOT NULL PRIMARY KEY,
    Version FLOAT NOT NULL,
    ParticipantID INT NOT NULL,
    DateSigned DATETIME NOT NULL,
    FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID)
);


-- Create SafetyData table
CREATE TABLE SafetyData (
    EventID INT IDENTITY NOT NULL PRIMARY KEY,
    Date DATETIME NOT NULL,
    Severity VARCHAR(5) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    ParticipantID INT NOT NULL,
    Phase VARCHAR(5) NOT NULL,
    TrialID INT NOT NULL,
    FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID),
    FOREIGN KEY (TrialID) REFERENCES ClinicalTrials(TrialID)
);

-- Create Visit table
CREATE TABLE Visit (
    VisitID INT IDENTITY NOT NULL PRIMARY KEY,
    VisitDate DATE NOT NULL,
    ParticipantID INT NOT NULL,
    Purpose VARCHAR(255) NOT NULL,
    FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID)
);

-- Create Assessment table
CREATE TABLE Assessment (
    DataPointID INT IDENTITY NOT NULL PRIMARY KEY,
    ParticipantID INT NOT NULL,
    AppointmentID INT NOT NULL,
    AssessmentType VARCHAR(100) NOT NULL,
    DateTime DATETIME NOT NULL,
    Result VARCHAR(20) NOT NULL,
    FOREIGN KEY (ParticipantID) REFERENCES Participant(ParticipantID),
    FOREIGN KEY (AppointmentID) REFERENCES Visit(VisitID)
);


-- create view for generating report about Participant Trial Information
CREATE VIEW vw_ParticipantTrialInformation AS
SELECT p.ParticipantID,
	p.FirstName, 
	p.LastName, 
	ct.TrialID, 
	ct.Title, 
	ti.PrincipalInvestigatorID,
	pi.FirstName AS PI_FirstName,
	pi.LastName AS PI_LastName
FROM Participant p 
INNER JOIN ClinicalTrials ct 
ON p.TrialID = ct.TrialID
INNER JOIN TrialInvestigator ti 
ON ct.TrialID = ti.TrialID
INNER JOIN PrincipalInvestigator pi 
ON ti.PrincipalInvestigatorID = pi.PrincipalInvestigatorID
--
SELECT * FROM vw_ParticipantTrialInformation;


-- create view for the Participant Visit Schedule Report,
-- This View will provide a schedule of upcoming participant visits, including dates and purposes.
CREATE VIEW vw_ParticipantVisitSchedule AS
SELECT
    v.VisitID,
    p.ParticipantID,
    p.FirstName,
    p.LastName,
    v.VisitDate,
    v.Purpose
FROM Visit v
JOIN Participant p ON v.ParticipantID = p.ParticipantID
WHERE v.VisitDate >= GETDATE();  -- only include upcoming visits
--
SELECT * FROM vw_ParticipantVisitSchedule
ORDER BY VisitDate;


-- create view for generating report about the Clinical Trial Progress
CREATE VIEW vw_ClinicalTrialProgress AS
SELECT
    ct.TrialID,
    ct.Title AS TrialTitle,
    ct.StartDate,
    ct.EndDate,
    COUNT(DISTINCT p.ParticipantID) AS ParticipantsCount,
    COUNT(DISTINCT v.VisitID) AS VisitsCount
FROM ClinicalTrials ct
LEFT JOIN Participant p ON ct.TrialID = p.TrialID
LEFT JOIN Visit v ON p.ParticipantID = v.ParticipantID
GROUP BY ct.TrialID, ct.Title, ct.StartDate, ct.EndDate;
--  
SELECT * FROM vw_ClinicalTrialProgress;


-- Create View to get counts for different Severity
CREATE VIEW vw_SafetyData AS
SELECT 
	sd.EventID, 
	sd.Date, sd.Severity, 
	sd.Description, 
	sd.ParticipantID,
	p.FirstName,
	p.LastName, 
	p.TrialID, 
	ct.Title AS TrialTitle
FROM SafetyData sd
INNER JOIN Participant p ON sd.ParticipantID = p.ParticipantID
INNER JOIN ClinicalTrials ct ON sd.TrialID = ct.TrialID;
--- 

SELECT * FROM vw_SafetyData;

SELECT Severity, COUNT(*) AS SeverityCount
FROM vw_SafetyData
GROUP BY Severity;


-- Create View to get Participant's Assesment
CREATE VIEW vw_ParticipantAssessment AS
SELECT
	a.DataPointID, 
	a.ParticipantID,
	a.AppointmentID, 
	a.AssessmentType,
	a.DateTime, 
	a.Result,
	p.FirstName, 
	p.LastName,
	p.DateOfBirth, 
	p.ConsentStatus, 
	p.SiteID, 
	v.VisitDate,
	v.Purpose
FROM Assessment a
INNER JOIN Participant p ON a.ParticipantID = p.ParticipantID
INNER JOIN Visit v ON a.AppointmentID = v.VisitID;

-- SELECT * from ParticipantAssessmentView;
SELECT 
	ParticipantID,
	FirstName,
	LastName,
	COUNT(DISTINCT AssessmentType) AS AssessmentTypesCount
FROM vw_ParticipantAssessment
GROUP BY ParticipantID, FirstName, LastName
ORDER BY AssessmentTypesCount DESC;

-- Average Age of Participant by Assessment Result
SELECT 
	pav.Result,
	AVG(pa.age) AS AverageAge
FROM vw_ParticipantAssessment pav
INNER JOIN Participant pa ON pav.ParticipantID = pa.ParticipantID
GROUP BY pav.Result;

-- Create View to get Medication information used in the Trial
CREATE VIEW vw_MedicationTrials AS
SELECT 
	m.MedicationID,
	m.Name AS MedicationName,
	m.Date AS MedicationDate,
	m.TrialID, 
	ct.Title AS TrialTitle, 
	ct.StartDate AS TrialStartDate, 
	ct.EndDate AS TrialEndDate
FROM Medication m
INNER JOIN ClinicalTrials ct ON m.TrialID = ct.TrialID;

-- Timeline of medications used across trials
SELECT TrialID, TrialTitle, COUNT(MedicationID) AS MedicationsUsed
FROM vw_MedicationTrials
GROUP BY TrialID, TrialTitle
ORDER BY MedicationsUsed DESC;



-- Insert Queries for above created tables
-- Insert data for 5 clinical trials related to joint pain treatment
INSERT INTO ClinicalTrials (Title, StartDate, EndDate) VALUES
('Efficacy of Drug X in Joint Pain Management', '2023-01-15', '2023-07-30'),
('Study on Novel Treatment for Arthritis', '2023-04-10', '2024-01-20'),
('Effectiveness of Therapy Y in Osteoarthritis Patients', '2023-09-22', '2024-06-15'),
('Long-term Impact of Drug Z in Rheumatoid Arthritis', '2023-06-05', '2025-02-28'),
('Comparative Analysis of Joint Pain Treatments', '2023-11-18', '2024-09-10'),
('Investigation of Exercise Regimen in Knee Pain Relief', '2023-02-28', '2023-08-15'),
('Assessment of New Therapeutic Approach for Rheumatoid Arthritis', '2023-07-10', '2024-03-22'),
('Exploration of Dietary Interventions in Joint Inflammation', '2023-10-14', '2024-05-05'),
('Trial for the Efficacy of Mindfulness in Chronic Pain Management', '2023-05-20', '2024-01-30'),
('Longitudinal Study on the Impact of Genetics on Arthritic Conditions', '2023-12-03', '2025-06-20');

-- Insert data for 10 principal investigators
INSERT INTO PrincipalInvestigator (FirstName, LastName, Experience) VALUES
('John', 'Smith', 8),
('Emily', 'Johnson', 6),
('Michael', 'Williams', 10),
('Sophia', 'Brown', 4),
('William', 'Jones', 7),
('Emma', 'Miller', 5),
('Alexander', 'Davis', 9),
('Olivia', 'Garcia', 3),
('James', 'Martinez', 12),
('Ava', 'Lopez', 7);



-- Insert data into TrialInvestigator table to establish relationships
INSERT INTO TrialInvestigator (TrialID, PrincipalInvestigatorID) VALUES
(1, 1), 
(4, 2),  
(8, 3),  
(9, 4), 
(10, 5),
(6, 6),
(7, 7),
(3, 8),
(2, 9),
(5, 10);

-- Insert 10 records into the Medication table
INSERT INTO Medication(Name, Date, TrialID) VALUES
('Ibuprofen', '2023-01-15', 1),
('Acetaminophen', '2023-03-20', 4),
('Naproxen', '2023-05-10', 8),
('Aspirin', '2023-06-05', 9),
('Celecoxib', '2023-08-18', 10),
('Diclofenac', '2023-09-30', 6),
('Meloxicam', '2023-10-12', 7),
('Tramadol', '2023-11-25', 3),
('Prednisone', '2023-12-10', 2),
('Oxycodone', '2024-01-05', 5);


-- Insert 20 entries into the Dosage table while considering the constraint
INSERT INTO Dosage (DosageAmount, DosageUnit, Frequency, RouteofAdministrationType, MedicationID)
VALUES
(10, 'mg', 2, 'oral', 1),
(20, 'ml', 1, 'intravenous', 2),
(15, 'mg', 1, 'intramuscular', 3),
(30, 'mg', 3, 'oral', 1),
(25, 'ml', 1, 'intravenous', 2),
(20, 'mg', 1, 'intramuscular', 6),
(40, 'mg', 3, 'oral', 5),
(30, 'ml', 1, 'intravenous', 3),
(35, 'mg', 1, 'intramuscular', 8),
(15, 'mg', 1, 'oral', 10),
(45, 'ml', 1, 'intravenous', 4),
(22, 'mg', 1, 'intramuscular', 4),
(20, 'mg', 2, 'oral', 2),
(28, 'ml', 1, 'intravenous', 6),
(18, 'mg', 1, 'intramuscular', 7),
(12, 'mg', 1, 'oral', 8),
(36, 'ml', 1, 'intravenous', 9),
(27, 'mg', 1, 'intramuscular', 9),
(14, 'mg', 2, 'oral', 9),
(32, 'ml', 1, 'intravenous', 1);




-- Insert 3 values into the ClinicalSite table
INSERT INTO ClinicalSite (SiteName, Location) VALUES
('Roxbury clinic', 'Boston'),
('Manhattan Health Center', 'New York'),
('Philadelphia Medical Institute', 'Philadelphia'),
('Bayview Hospital', 'San Francisco'),
('Chicago Wellness Clinic', 'Chicago'),
('Houston Medical Center', 'Houston'),
('Miami Pain Management Institute', 'Miami'),
('Seattle Rheumatology Center', 'Seattle'),
('Denver Arthritis Clinic', 'Denver'),
('Atlanta Orthopedic Center', 'Atlanta');


-- Insert 10 entries into the Participant table
INSERT INTO Participant (TrialID, MedicalHistoryID, FirstName, LastName, ConsentStatus, ContactInformation, SiteID, DateOfBirth) VALUES
(1, 1, 'John', 'Doe', 'Y', 8573135150, 1, '1990-05-15'),
(2, 2, 'Alice', 'Smith', 'N', 8573135151, 2, '1987-12-28'),
(3, 3, 'Michael', 'Johnson', 'Y', 8573135152, 3, '1985-09-10'),
(4, 4, 'Sarah', 'Williams', 'N', 8573135153, 1, '1992-07-03'),
(5, 5, 'Emily', 'Brown', 'Y', 8573135154, 2, '1998-03-20'),
(1, 6, 'David', 'Jones', 'N', 8573135155, 3, '1995-11-18'),
(2, 7, 'Olivia', 'Martinez', 'N', 8573135156, 1, '1991-06-25'),
(3, 8, 'Daniel', 'Garcia', 'Y', 8573135157, 2, '1989-02-12'),
(4, 9, 'Sophia', 'Lopez', 'N', 8573135158, 3, '1994-08-05'),
(5, 10, 'Noah', 'Hernandez', 'Y', 8573135159, 1, '1997-01-30');



-- Insert 10 entries into the MedicalHistory table
INSERT INTO MedicalHistory (ParticipantID, PrimaryMedication, Surgery, RecurringPatient) VALUES
(1, 'Paracetamol', 2, 'Y'),
(2, 'Ibuprofen', 0, 'N'),
(3, 'Aspirin', 1, 'Y'),
(4, 'Celecoxib', 3, 'N'),
(5, 'Naproxen', 2, 'Y'),
(6, 'Tramadol', 1, 'N'),
(7, 'Meloxicam', 0, 'N'),
(8, 'Diclofenac', 2, 'Y'),
(9, 'Prednisone', 1, 'N'),
(10, 'Oxycodone', 0, 'Y');


-- Insert 10 entries into the InformedConsentForm
INSERT INTO InformedConsentForm (Version, ParticipantID, DateSigned) VALUES
(1.0, 1, '2023-02-22'),
(1.0, 3, '2023-02-23'),
(2.0, 2, '2023-04-12'),
(1.0, 4, '2023-02-24'),
(2.0, 5, '2023-06-02'),
(1.0, 6, '2023-02-25'),
(1.0, 7, '2023-02-26'),
(1.0, 9, '2023-07-15'),
(1.0, 10, '2023-02-27'),
(1.0, 8, '2023-03-05');


-- Insert 20 values into the SafetyData table
INSERT INTO SafetyData (Date, Severity, Description, ParticipantID, Phase, TrialID) VALUES
('2023-01-05', 'II', 'Nausea', 1, 'I', 1),
('2023-02-10', 'III', 'Headache', 2, 'II', 2),
('2023-03-15', 'I', 'F3ue', 3, 'III', 3),
('2023-04-20', 'IV', 'Dizziness', 4, 'IV', 4),
('2023-05-25', 'II', 'Insomnia', 5, 'I', 5),
('2023-06-30', 'III', 'Joint pain', 6, 'II', 1),
('2023-07-05', 'I', 'Fever', 7, 'III', 2),
('2023-08-10', 'IV', 'Shortness of breath', 8, 'IV', 3),
('2023-09-15', 'II', 'Stomachache', 9, 'I', 4),
('2023-10-20', 'III', 'Chest pain', 10, 'II', 5),
('2023-11-25', 'I', 'Vomiting', 1, 'III', 1),
('2023-12-30', 'II', 'Anxiety', 2, 'IV', 2),
('2024-01-05', 'III', 'Back pain', 3, 'I', 3),
('2024-02-10', 'IV', 'Migraine', 4, 'II', 4),
('2024-03-15', 'II', 'Allergy', 5, 'III', 5),
('2024-04-20', 'III', 'Constipation', 6, 'IV', 1),
('2024-05-25', 'I', 'Sore throat', 7, 'I', 2),
('2024-06-30', 'IV', 'Blurred vision', 8, 'II', 3),
('2024-07-05', 'II', 'Cough', 9, 'III', 4),
('2024-08-10', 'III', 'Rash', 10, 'IV', 5);


-- Insert 15 values into the Visit table
INSERT INTO Visit (VisitDate, ParticipantID, Purpose) VALUES
('2023-01-15', 1, 'Regular checkup'),
('2023-02-20', 2, 'Follow-up appointment'),
('2023-03-25', 3, 'Consultation'),
('2023-04-30', 4, 'Treatment review'),
('2023-05-05', 5, 'Health assessment'),
('2023-06-10', 6, 'Medication refill'),
('2023-07-15', 7, 'Diagnostic test'),
('2023-08-20', 8, 'Therapy session'),
('2023-09-25', 9, 'Physical examination'),
('2023-10-30', 10, 'Counseling session'),
('2023-11-05', 1, 'Regular checkup'),
('2023-12-10', 2, 'Follow-up appointment'),
('2024-01-15', 3, 'Consultation'),
('2024-02-20', 4, 'Treatment review'),
('2024-03-25', 5, 'Health assessment');


-- Insert 15 values into the Assessment table
INSERT INTO Assessment (ParticipantID, AppointmentID, AssessmentType, DateTime, Result) VALUES
(1, 1, 'Lab Test', '2023-01-15 08:00:00', 'Positive'),
(2, 2, 'Questionnaire', '2023-02-20 09:30:00', 'Negative'),
(3, 3, 'Lab Test', '2023-03-25 10:45:00', 'Positive'),
(4, 4, 'Questionnaire', '2023-04-30 11:15:00', 'Negative'),
(5, 5, 'Lab Test', '2023-05-05 13:00:00', 'Positive'),
(6, 6, 'Questionnaire', '2023-06-10 14:30:00', 'Negative'),
(7, 7, 'Lab Test', '2023-07-15 15:45:00', 'Positive'),
(8, 8, 'Questionnaire', '2023-08-20 16:15:00', 'Negative'),
(9, 9, 'Lab Test', '2023-09-25 08:30:00', 'Positive'),
(10, 10, 'Questionnaire', '2023-10-30 09:45:00', 'Negative'),
(1, 11, 'Lab Test', '2023-11-05 10:00:00', 'Positive'),
(2, 12, 'Questionnaire', '2023-12-10 11:30:00', 'Negative'),
(3, 13, 'Lab Test', '2024-01-15 13:15:00', 'Positive'),
(4, 14, 'Questionnaire', '2024-02-20 14:45:00', 'Negative'),
(5, 15, 'Lab Test', '2024-03-25 16:00:00', 'Positive');
