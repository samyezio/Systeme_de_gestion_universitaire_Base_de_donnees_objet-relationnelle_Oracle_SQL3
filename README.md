# University Course Management System (UCMS)

This repository contains the SQL scripts required to implement a University Course Management System using Oracle SQL3-based object-relational database. The system efficiently manages students, professors, departments, courses, enrollments, classrooms, assignments, and grading.

## Overview

The UCMS integrates advanced object-relational features, including:
- Object types
- REF types
- Nested tables
- Views
- Triggers

It provides a comprehensive solution for managing all aspects of university courses, from department organization to student grading.

## Repository Structure

```
ucms-repo/
├── createUserScript.sql     # Creates database user with appropriate privileges
├── creationScript.sql       # Creates all tables, object types, views, triggers
├── sampleData.sql           # Populates tables with sample data
├── triggerTest.sql          # Test cases for business rules and constraints
└── README.md                # This file
```

## Getting Started

### Prerequisites

- Oracle Database 12c or higher
- SQL*Plus or another Oracle SQL client

### Installation

1. **Connect to your Oracle Database as a user with administrative privileges**:
   ```
   sqlplus system/your_password@localhost:1521/your_service
   ```

2. **Create the UCMS user and grant privileges**:
   ```
   @createUserScript.sql
   ```

3. **Connect as the newly created UCMS user**:
   ```
   connect ucms/ucms_password@localhost:1521/your_service
   ```

4. **Create the database schema**:
   ```
   @creationScript.sql
   ```

5. **Populate with sample data**:
   ```
   @sampleData.sql
   ```

6. **Test business rules and constraints**:
   ```
   @triggerTest.sql
   ```

## System Features

### Entities
- **Departments**: Identified by dept_id and name, led by a head professor
- **Students**: Characterized by student_id, name, email, date of birth, and address
- **Professors**: Described by prof_id, name, email, department, and phone_numbers
- **Courses**: Defined by course_id, course_name, coefficient, syllabus, and assignments
- **Classrooms**: Specified by room_number and capacity
- **Assignments**: Include assignment_id, title, description, and due_date
- **Grades**: Stored for each student assignment

### Business Rules and Constraints
- Students cannot enroll in the same course more than once
- Each course can have multiple assignments, but each assignment belongs to only one course
- Grades are recorded for each student per assignment
- Each department must have a head professor, and a professor can head only one department
- Courses must be assigned to valid classrooms with sufficient capacity
- No two courses assigned to the same classroom can overlap in time
- Courses with enrolled students cannot be deleted

### Views
- Students and their enrolled courses
- Student transcripts with all grades
- Weekly schedules for students and professors
- Total number of students in each course
- Students who haven't submitted assignments
- Student with the highest average
- Average grade for each course

## Implementation Details

### Object Types
The system implements the following object types:
- Address_Type
- Phone_Numbers_Type (nested table)
- Department_Type
- Professor_Type
- Student_Type
- Course_Type
- Assignment_Type
- Classroom_Type
- TimeSlot_Type
- Grade_Type

### Relationships
Relationships are implemented using REF types, enabling navigation between related objects.

## Usage Flow

1. First, run `createUserScript.sql` to create a new Oracle user with the necessary privileges
2. Connect to the newly created user account
3. Run `creationScript.sql` to create all the object types, tables, constraints, triggers, and views
4. Run `sampleData.sql` to populate the database with test data
5. Run `triggerTest.sql` to validate that all business rules and constraints work as expected

## Contributors

This project was developed for the USTHB ING3-Security Computer Science Faculty, Module: A-DB 2024/2025.

## License

This project is licensed under the MIT License - see the LICENSE file for details.# University Course Management System (UCMS)

