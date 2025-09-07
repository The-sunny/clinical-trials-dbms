#📘 Clinical Trials Database
Overview

The Clinical Trials Database is designed to support the management and documentation of clinical trials. It serves as a centralized system to store and organize information about trials, participants, investigators, medical history, medications, safety data, and more. The goal is to streamline trial operations, ensure compliance with ethical and regulatory standards, and provide reliable data for analysis and reporting.

Entity–Relationship Diagram

The database was modeled using Crow’s Foot notation with clear primary keys and relationships.

<img width="1321" height="745" alt="image" src="https://github.com/user-attachments/assets/2629722b-e180-4444-93e1-0a4123ca5e45" />


Key Features

Participant Enrollment Tracking – Monitor how many participants are enrolled in each trial.

Site Performance Evaluation – Track participant visits and site performance to identify strong or weak performing sites.

Safety Monitoring – Record and track adverse events and safety concerns for participants and medications.

Progress Tracking – Monitor trial timelines and identify potential delays.

Compliance Management – Store consent forms and ensure participants meet ethical and regulatory requirements.

Resource Allocation – Track investigator medications and distribute them efficiently across trials.

Outcome Analysis – Provide preliminary insights into treatment efficacy and safety.

Efficient Reporting – Generate required reports for regulatory authorities, sponsors, and ethics committees.

Business Rules

One Principal Investigator is assigned to only one clinical trial.

Each Participant may have only one medical history record.

Medications can have multiple doses (including placebos).

A Participant can visit clinics multiple times, and each visit will include an assessment.

Database Entities

Clinical Trial – Core entity holding trial details (trial ID, title, dates, etc.).

Principal Investigator – Investigator responsible for trial oversight.

Participant – Details of individuals participating in the trial.

Informed Consent Form – Consent records signed by participants.

Trial Investigator – Relationship entity linking investigators to trials.

Visit – Participant visits for screenings, treatments, or follow-ups.

Assessment – Clinical data collected during participant visits.

Medication & Dosage – Information on trial medications, doses, and protocols.

Medical History – Participant’s health background and eligibility assessment.

Safety Data – Records of adverse events and safety monitoring.

Clinical Site – Information on physical locations where trials take place.

Tech Stack

Database: SQL-based (ER model using Crow’s Foot notation)

Modeling Tool: [Insert tool name if you used Lucidchart, Draw.io, etc.]

Environment: macOS (development)
