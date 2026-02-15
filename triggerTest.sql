-- =========================================================
-- UNIVERSITY COURSE MANAGEMENT SYSTEM (UCMS) - TRIGGER TESTING WITH SAMPLE DATA
-- =========================================================
-- This script tests all the triggers and constraints using existing sample data
-- Run this after the sample data insertion script
-- =========================================================

-- Enable DBMS_OUTPUT to see test results
SET SERVEROUTPUT ON;

-- Begin test sequence
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== BEGINNING TRIGGER AND CONSTRAINT TESTS WITH SAMPLE DATA =====');
END;
/

-- TEST 1: Prevent duplicate enrollment
-- Tests: A student cannot enroll in the same course more than once
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 1: Prevent duplicate enrollment');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Student already enrolled in this course');
    
    DECLARE
        v_student_id NUMBER;
        v_course_id NUMBER;
        v_student_ref REF student_t;
        v_course_ref REF course_t;
    BEGIN
        -- Get an existing student and course where the student is already enrolled
        SELECT e.student_id, e.course_id, e.student_ref, e.course_ref
        INTO v_student_id, v_course_id, v_student_ref, v_course_ref
        FROM enrollments e
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using student ID ' || v_student_id || ' who is already enrolled in course ID ' || v_course_id);
        
        -- Attempt to enroll the same student in the same course again (should fail)
        BEGIN
            INSERT INTO enrollments VALUES (
                enroll_seq.NEXTVAL, 
                v_student_id, 
                v_course_id, 
                SYSDATE, 
                v_student_ref, 
                v_course_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Duplicate enrollment was allowed');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 2: Classroom capacity check
-- Tests: A course must be assigned to a classroom with sufficient capacity
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 2: Classroom capacity check');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Classroom capacity is insufficient');
    
    DECLARE
        v_small_classroom_ref REF classroom_t;
        v_dept_ref REF department_t;
        v_course_id NUMBER;
        v_student_id1 NUMBER;
        v_student_id2 NUMBER;
        v_student_ref1 REF student_t;
        v_student_ref2 REF student_t;
        v_course_ref REF course_t;
    BEGIN
        -- Create a small capacity classroom for testing
        INSERT INTO classrooms VALUES (classroom_t('SMALL_TEST', 1));
        DBMS_OUTPUT.PUT_LINE('  Created test classroom with capacity of 1');
        
        -- Get the classroom reference
        SELECT REF(c) INTO v_small_classroom_ref
        FROM classrooms c
        WHERE c.room_number = 'SMALL_TEST';
        
        -- Get a department reference
        SELECT REF(d) INTO v_dept_ref
        FROM departments d
        WHERE ROWNUM = 1;
        
        -- Create a course that uses the small classroom
        v_course_id := course_seq.NEXTVAL;
        INSERT INTO courses VALUES (
            course_t(
                v_course_id,
                'Small Capacity Test Course',
                3,
                'Testing classroom capacity constraint',
                v_dept_ref,
                v_small_classroom_ref,
                time_slot_t('Friday', TIMESTAMP '2024-01-01 08:00:00', TIMESTAMP '2024-01-01 09:00:00'),
                assignment_list_t()
            )
        );
        DBMS_OUTPUT.PUT_LINE('  Created test course in small classroom');
        
        -- Get course reference
        SELECT REF(c) INTO v_course_ref
        FROM courses c
        WHERE c.course_id = v_course_id;
        
        -- Get two different students (one at a time)
        SELECT s.student_id, REF(s) 
        INTO v_student_id1, v_student_ref1
        FROM students s
        WHERE ROWNUM = 1;
        
        SELECT s.student_id, REF(s) 
        INTO v_student_id2, v_student_ref2
        FROM students s
        WHERE s.student_id != v_student_id1
        AND ROWNUM = 1;
        
        -- Enroll first student (should succeed)
        INSERT INTO enrollments VALUES (
            enroll_seq.NEXTVAL, 
            v_student_id1, 
            v_course_id, 
            SYSDATE, 
            v_student_ref1, 
            v_course_ref
        );
        DBMS_OUTPUT.PUT_LINE('  Successfully enrolled first student');
        
        -- Try to enroll second student (should fail due to capacity)
        BEGIN
            INSERT INTO enrollments VALUES (
                enroll_seq.NEXTVAL, 
                v_student_id2, 
                v_course_id, 
                SYSDATE, 
                v_student_ref2, 
                v_course_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Exceeded classroom capacity');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
        
        -- Clean up test data
        DELETE FROM enrollments WHERE course_id = v_course_id;
        DELETE FROM courses WHERE course_id = v_course_id;
        DELETE FROM classrooms WHERE room_number = 'SMALL_TEST';
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('  Test data cleaned up successfully');
    END;
END;
/

-- TEST 3: Time slot overlap check
-- Tests: No two courses in the same classroom overlap in time
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 3: Time slot overlap check');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Time slot overlaps with an existing course in the same classroom');
    
    DECLARE
        v_existing_course_id NUMBER;
        v_classroom_ref REF classroom_t;
        v_classroom_id VARCHAR2(20);
        v_dept_ref REF department_t;
        v_time_day VARCHAR2(10);
        v_time_start TIMESTAMP;
        v_time_end TIMESTAMP;
    BEGIN
        -- Get information about an existing course and its time slot
        SELECT c.course_id, c.classroom, c.time_slot.day_of_week, 
               c.time_slot.start_time, c.time_slot.end_time
        INTO v_existing_course_id, v_classroom_ref, v_time_day, v_time_start, v_time_end
        FROM courses c
        WHERE ROWNUM = 1;
        
        -- Get department reference
        SELECT REF(d) INTO v_dept_ref
        FROM departments d
        WHERE ROWNUM = 1;
        
        -- Get classroom ID for debugging
        SELECT c.room_number INTO v_classroom_id
        FROM classrooms c
        WHERE REF(c) = v_classroom_ref;
        
        DBMS_OUTPUT.PUT_LINE('  Using classroom ' || v_classroom_id || ' which has a course on ' || 
                             v_time_day || ' from ' || TO_CHAR(v_time_start, 'HH24:MI') || 
                             ' to ' || TO_CHAR(v_time_end, 'HH24:MI'));
        
        -- Calculate an overlapping time (start in the middle of the existing course)
        v_time_start := v_time_start + INTERVAL '30' MINUTE;
        v_time_end := v_time_end + INTERVAL '30' MINUTE;
        
        -- Try to create a course with overlapping time slot (should fail)
        BEGIN
            INSERT INTO courses VALUES (
                course_t(
                    course_seq.NEXTVAL,
                    'Test Overlap Course',
                    3,
                    'Testing time slot overlap constraint',
                    v_dept_ref,
                    v_classroom_ref,
                    time_slot_t(v_time_day, v_time_start, v_time_end),
                    assignment_list_t()
                )
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Overlapping course was created');
            
            -- Clean up if it somehow succeeded
            DELETE FROM courses WHERE course_name = 'Test Overlap Course';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 4: Prevent course deletion if students are enrolled
-- Tests: Prevent Course Deletion if Students Are Enrolled
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 4: Prevent course deletion if students are enrolled');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Cannot delete course with enrolled students');
    
    DECLARE
        v_course_id NUMBER;
        v_enrollment_count NUMBER;
    BEGIN
        -- Find a course with enrolled students - using a subquery to avoid ROWNUM with GROUP BY
        SELECT course_id, cnt
        INTO v_course_id, v_enrollment_count
        FROM (
            SELECT c.course_id, COUNT(e.id) as cnt
            FROM courses c
            JOIN enrollments e ON c.course_id = e.course_id
            GROUP BY c.course_id
            HAVING COUNT(e.id) > 0
            ORDER BY COUNT(e.id) DESC
        )
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using course ID ' || v_course_id || ' with ' || v_enrollment_count || ' enrolled student(s)');
        
        -- Try to delete the course (should fail)
        BEGIN
            DELETE FROM courses WHERE course_id = v_course_id;
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Course with enrolled students was deleted');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 5: Department must have head professor
-- Tests: Each department must have a head professor
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 5: Department must have head professor');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Each department must have a head professor');
    
    DECLARE
        v_dept_id NUMBER;
    BEGIN
        -- Get a new department ID
        v_dept_id := dept_seq.NEXTVAL;
        
        -- Try to insert department with NULL head_prof using dynamic SQL to bypass compile-time checks
        BEGIN
            EXECUTE IMMEDIATE 'INSERT INTO departments (dept_id, name, head_prof) VALUES (:1, :2, NULL)'
            USING v_dept_id, 'Test Department Without Head';
            
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Department without head professor was created');
            -- Clean up if it somehow succeeded
            EXECUTE IMMEDIATE 'DELETE FROM departments WHERE dept_id = :1' USING v_dept_id;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 6: Professor can head only one department
-- Tests: A professor can head only one department
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 6: Professor can head only one department');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - A professor can head only one department');
    
    DECLARE
        v_prof_ref REF professor_t;
        v_prof_name VARCHAR2(100);
    BEGIN
        -- Find a professor who is already a department head
        SELECT d.head_prof, DEREF(d.head_prof).name
        INTO v_prof_ref, v_prof_name
        FROM departments d
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using professor ' || v_prof_name || ' who already heads a department');
        
        -- Try to create a new department with the same head professor (should fail)
        BEGIN
            INSERT INTO departments VALUES (
                department_t(
                    dept_seq.NEXTVAL,
                    'Test Department Duplicate Head',
                    v_prof_ref
                )
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Created second department with same head professor');
            
            -- Clean up if it somehow succeeded
            DELETE FROM departments WHERE name = 'Test Department Duplicate Head';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 7: Grade value check constraint (0-20 scale)
-- Tests: Grades are recorded for each student per assignment within valid range
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 7: Grade value check constraint');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Grade value must be between 0 and 20');
    
    DECLARE
        v_student_id NUMBER;
        v_course_id NUMBER;
        v_assignment_id NUMBER;
        v_professor_id NUMBER;
        v_student_ref REF student_t;
        v_course_ref REF course_t;
        v_professor_ref REF professor_t;
    BEGIN
        -- Get data for an existing student, course, assignment and professor
        SELECT g.student_id, g.course_id, g.assignment_id, g.professor_id,
               g.student_ref, g.course_ref, g.professor_ref
        INTO v_student_id, v_course_id, v_assignment_id, v_professor_id,
             v_student_ref, v_course_ref, v_professor_ref
        FROM grades g
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using student ID ' || v_student_id || ' course ID ' || v_course_id || 
                           ' assignment ID ' || v_assignment_id);
        
        -- Try to insert a grade with a value > 20 (should fail)
        BEGIN
            INSERT INTO grades VALUES (
                grade_seq.NEXTVAL,
                v_student_id,
                v_course_id,
                v_assignment_id,
                21, -- Invalid grade value (> 20)
                SYSDATE,
                v_professor_id,
                v_student_ref,
                v_course_ref,
                v_professor_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Inserted grade with value > 20');
            ROLLBACK;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
        
        -- Try to insert a grade with a value < 0 (should fail)
        BEGIN
            INSERT INTO grades VALUES (
                grade_seq.NEXTVAL,
                v_student_id,
                v_course_id,
                v_assignment_id,
                -1, -- Invalid grade value (< 0)
                SYSDATE,
                v_professor_id,
                v_student_ref,
                v_course_ref,
                v_professor_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Inserted grade with value < 0');
            ROLLBACK;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 8: Course coefficient check constraint 
-- Tests: Additional check on course coefficient values
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 8: Course coefficient check constraint');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Coefficient must be greater than 0');
    
    DECLARE
        v_dept_ref REF department_t;
        v_classroom_ref REF classroom_t;
    BEGIN
        -- Get references to an existing department and classroom
        SELECT REF(d) INTO v_dept_ref
        FROM departments d
        WHERE ROWNUM = 1;
        
        SELECT REF(c) INTO v_classroom_ref
        FROM classrooms c
        WHERE ROWNUM = 1;
        
        -- Try to create a course with zero coefficient (should fail)
        BEGIN
            INSERT INTO courses VALUES (
                course_t(
                    course_seq.NEXTVAL,
                    'Zero Coefficient Course',
                    0, -- Invalid coefficient (should be > 0)
                    'Testing coefficient constraint',
                    v_dept_ref,
                    v_classroom_ref,
                    time_slot_t('Saturday', TIMESTAMP '2024-01-01 08:00:00', TIMESTAMP '2024-01-01 09:00:00'),
                    assignment_list_t()
                )
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Created course with zero coefficient');
            -- Clean up if it somehow succeeded
            DELETE FROM courses WHERE course_name = 'Zero Coefficient Course';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
        
        -- Try to create a course with negative coefficient (should fail)
        BEGIN
            INSERT INTO courses VALUES (
                course_t(
                    course_seq.NEXTVAL,
                    'Negative Coefficient Course',
                    -1, -- Invalid coefficient (should be > 0)
                    'Testing coefficient constraint',
                    v_dept_ref,
                    v_classroom_ref,
                    time_slot_t('Saturday', TIMESTAMP '2024-01-01 08:00:00', TIMESTAMP '2024-01-01 09:00:00'),
                    assignment_list_t()
                )
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Created course with negative coefficient');
            -- Clean up if it somehow succeeded
            DELETE FROM courses WHERE course_name = 'Negative Coefficient Course';
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- Final test summary
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== TRIGGER AND CONSTRAINT TESTS COMPLETED =====');
    DBMS_OUTPUT.PUT_LINE('All constraints and triggers have been tested.');
END;
/
-- =========================================================
-- ADDITIONAL TRIGGER TESTS FOR MISSING BUSINESS RULES
-- =========================================================
-- Tests for the two business rules that were not fully tested:
-- 1. Each course can have multiple assignments, but each assignment belongs to only one course
-- 2. Grades are recorded for each student per assignment (no duplicates)
-- =========================================================

-- Enable DBMS_OUTPUT to see test results
SET SERVEROUTPUT ON;

-- Begin additional test sequence
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== ADDITIONAL BUSINESS RULE TESTS =====');
END;
/

-- TEST 9: Each assignment belongs to only one course
-- Tests: Each course can have multiple assignments, but each assignment belongs to only one course
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 9: Assignment belongs to only one course');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Assignment cannot belong to multiple courses');
    
    DECLARE
        v_course_id1 NUMBER;
        v_course_id2 NUMBER;
        v_assignment_id NUMBER;
    BEGIN
        -- Get two different course IDs
        SELECT c.course_id INTO v_course_id1 
        FROM courses c 
        WHERE ROWNUM = 1;
        
        SELECT c.course_id INTO v_course_id2 
        FROM courses c 
        WHERE c.course_id != v_course_id1 
        AND ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using course IDs ' || v_course_id1 || ' and ' || v_course_id2);
        
        -- Create a new assignment for the first course
        v_assignment_id := assign_seq.NEXTVAL;
        INSERT INTO assignments VALUES (
            v_assignment_id,
            'Test Assignment Uniqueness',
            'Testing assignment uniqueness constraint',
            TO_DATE('2024-05-01', 'YYYY-MM-DD'),
            v_course_id1
        );
        DBMS_OUTPUT.PUT_LINE('  Created assignment ' || v_assignment_id || ' for course ' || v_course_id1);
        
        -- Try to create another assignment with the same ID for a different course (should fail)
        BEGIN
            INSERT INTO assignments VALUES (
                v_assignment_id, -- Same assignment ID
                'Duplicate Assignment Test',
                'This should fail',
                TO_DATE('2024-05-02', 'YYYY-MM-DD'),
                v_course_id2 -- Different course
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Assignment was assigned to multiple courses');
            
            -- Clean up if it somehow succeeded
            DELETE FROM assignments WHERE assignment_id = v_assignment_id;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
                -- Clean up the test assignment
                DELETE FROM assignments WHERE assignment_id = v_assignment_id;
        END;
        
        -- Test that a course CAN have multiple assignments (positive test)
        DECLARE
            v_assignment_id2 NUMBER;
        BEGIN
            v_assignment_id2 := assign_seq.NEXTVAL;
            INSERT INTO assignments VALUES (
                v_assignment_id2,
                'Second Assignment for Same Course',
                'Testing that one course can have multiple assignments',
                TO_DATE('2024-05-03', 'YYYY-MM-DD'),
                v_course_id1 -- Same course as before
            );
            DBMS_OUTPUT.PUT_LINE('  POSITIVE TEST PASSED: Course can have multiple assignments');
            
            -- Clean up
            DELETE FROM assignments WHERE assignment_id = v_assignment_id2;
        END;
    END;
END;
/

-- TEST 10: Unique grades per student per assignment
-- Tests: Grades are recorded for each student per assignment (no duplicate grades)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 10: Unique grades per student per assignment');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Student cannot have duplicate grades for same assignment');
    
    DECLARE
        v_student_id NUMBER;
        v_course_id NUMBER;
        v_assignment_id NUMBER;
        v_professor_id NUMBER;
        v_student_ref REF student_t;
        v_course_ref REF course_t;
        v_professor_ref REF professor_t;
        v_grade_id NUMBER;
    BEGIN
        -- Get an existing grade to use the same student, course, assignment, and professor
        SELECT g.student_id, g.course_id, g.assignment_id, g.professor_id,
               g.student_ref, g.course_ref, g.professor_ref
        INTO v_student_id, v_course_id, v_assignment_id, v_professor_id,
             v_student_ref, v_course_ref, v_professor_ref
        FROM grades g
        WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('  Using student ID ' || v_student_id || 
                           ' for assignment ID ' || v_assignment_id || 
                           ' in course ID ' || v_course_id);
        
        -- Try to insert another grade for the same student, course, and assignment (should fail)
        BEGIN
            INSERT INTO grades VALUES (
                grade_seq.NEXTVAL,
                v_student_id,    -- Same student
                v_course_id,     -- Same course  
                v_assignment_id, -- Same assignment
                15,              -- Different grade value
                SYSDATE,
                v_professor_id,
                v_student_ref,
                v_course_ref,
                v_professor_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Duplicate grade was inserted');
            ROLLBACK;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
        
        -- Test that the same student CAN have grades for different assignments (positive test)
        DECLARE
            v_different_assignment_id NUMBER;
        BEGIN
            -- Find a different assignment in the same course
            SELECT a.assignment_id INTO v_different_assignment_id
            FROM assignments a
            WHERE a.course_id = v_course_id
            AND a.assignment_id != v_assignment_id
            AND ROWNUM = 1;
            
            -- Check if this student already has a grade for this different assignment
            DECLARE
                v_existing_grade_count NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_existing_grade_count
                FROM grades g
                WHERE g.student_id = v_student_id
                AND g.course_id = v_course_id
                AND g.assignment_id = v_different_assignment_id;
                
                IF v_existing_grade_count = 0 THEN
                    -- Insert grade for different assignment (should succeed)
                    v_grade_id := grade_seq.NEXTVAL;
                    INSERT INTO grades VALUES (
                        v_grade_id,
                        v_student_id,
                        v_course_id,
                        v_different_assignment_id, -- Different assignment
                        16,
                        SYSDATE,
                        v_professor_id,
                        v_student_ref,
                        v_course_ref,
                        v_professor_ref
                    );
                    DBMS_OUTPUT.PUT_LINE('  POSITIVE TEST PASSED: Student can have grades for different assignments');
                    
                    -- Clean up
                    DELETE FROM grades WHERE id = v_grade_id;
                ELSE
                    DBMS_OUTPUT.PUT_LINE('  POSITIVE TEST SKIPPED: Student already has grade for different assignment');
                END IF;
            END;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('  POSITIVE TEST SKIPPED: No other assignments found in same course');
        END;
    END;
END;
/

-- TEST 11: Assignment foreign key constraint
-- Tests: Assignment must belong to a valid course
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 11: Assignment must belong to valid course');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Assignment must reference existing course');
    
    DECLARE
        v_invalid_course_id NUMBER := 99999; -- Non-existent course ID
    BEGIN
        -- Try to create assignment with invalid course_id (should fail)
        BEGIN
            INSERT INTO assignments VALUES (
                assign_seq.NEXTVAL,
                'Invalid Course Assignment',
                'Testing foreign key constraint',
                TO_DATE('2024-05-01', 'YYYY-MM-DD'),
                v_invalid_course_id -- Invalid course ID
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Assignment with invalid course was created');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED: ' || SQLERRM);
        END;
    END;
END;
/

-- TEST 12: Grade foreign key constraints
-- Tests: Grades must reference valid student, course, assignment, and professor
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST 12: Grade must reference valid entities');
    DBMS_OUTPUT.PUT_LINE('Expected: Error - Grade must reference existing student, course, assignment, professor');
    
    DECLARE
        v_valid_student_id NUMBER;
        v_valid_course_id NUMBER;
        v_valid_assignment_id NUMBER;
        v_valid_professor_id NUMBER;
        v_student_ref REF student_t;
        v_course_ref REF course_t;
        v_professor_ref REF professor_t;
    BEGIN
        -- Get valid references for most fields
        SELECT s.student_id, REF(s) INTO v_valid_student_id, v_student_ref 
        FROM students s WHERE ROWNUM = 1;
        
        SELECT c.course_id, REF(c) INTO v_valid_course_id, v_course_ref 
        FROM courses c WHERE ROWNUM = 1;
        
        SELECT a.assignment_id INTO v_valid_assignment_id 
        FROM assignments a WHERE ROWNUM = 1;
        
        SELECT p.prof_id, REF(p) INTO v_valid_professor_id, v_professor_ref 
        FROM professors p WHERE ROWNUM = 1;
        
        -- Test invalid student ID
        BEGIN
            INSERT INTO grades VALUES (
                grade_seq.NEXTVAL,
                99999, -- Invalid student ID
                v_valid_course_id,
                v_valid_assignment_id,
                15,
                SYSDATE,
                v_valid_professor_id,
                v_student_ref,
                v_course_ref,
                v_professor_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Grade with invalid student was created');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED (Invalid Student): ' || SUBSTR(SQLERRM, 1, 50));
        END;
        
        -- Test invalid assignment ID
        BEGIN
            INSERT INTO grades VALUES (
                grade_seq.NEXTVAL,
                v_valid_student_id,
                v_valid_course_id,
                99999, -- Invalid assignment ID
                15,
                SYSDATE,
                v_valid_professor_id,
                v_student_ref,
                v_course_ref,
                v_professor_ref
            );
            DBMS_OUTPUT.PUT_LINE('  TEST FAILED: Grade with invalid assignment was created');
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  TEST PASSED (Invalid Assignment): ' || SUBSTR(SQLERRM, 1, 50));
        END;
    END;
END;
/

-- Final test summary for additional rules
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== ADDITIONAL BUSINESS RULE TESTS COMPLETED =====');
    DBMS_OUTPUT.PUT_LINE('Tested:');
    DBMS_OUTPUT.PUT_LINE('- Assignment uniqueness per course');
    DBMS_OUTPUT.PUT_LINE('- Multiple assignments per course allowed');
    DBMS_OUTPUT.PUT_LINE('- Unique grades per student per assignment');
    DBMS_OUTPUT.PUT_LINE('- Grade foreign key constraints');
    DBMS_OUTPUT.PUT_LINE('- Assignment foreign key constraints');
END;
/