# This class is used to generate the Query that helps fetch the result set 
# for Grading Queue page for a professor or TA.
# 
# Author - Surya Kiran
# Change log:
# 10/27 - Initial Add
# 

class DeliverableQueryHelper
	def self.generate_query_for_team_deliverables(course, current_user, team_selection)
		if team_selection == TeamSelection::MY_TEAMS
			faculty_id = current_user.id

			where_clause = " and (teams.primary_faculty_id = #{faculty_id} or teams.secondary_faculty_id = #{faculty_id}) "

			get_team_deliverables_query(course.id, where_clause)
		elsif team_selection == TeamSelection::ALL_TEAMS
			get_team_deliverables_query(course.id)
		end
	end

	def self.generate_query_for_individual_deliverables(course, current_user, team_selection)
		if team_selection == TeamSelection::MY_TEAMS
			where_clause = " and stud_course_team_advisor_view.advisor_name = '#{current_user.human_name}' "

			get_individual_deliverables_query(course.id, where_clause)
		elsif team_selection == TeamSelection::ALL_TEAMS
			get_individual_deliverables_query(course.id)
		end
	end

	def self.get_team_deliverables_query(course_id, append_where_clause = '')
	  sql_query = 'select distinct courses.name as course_name ' +
	      ', assignments.task_number ' +
	      ', assignments.name as deliverable_name ' +
	      ', teams.name as owner_name ' +
	      ', users.human_name as advisor_name ' +
	      ', case when grades.is_student_visible = \'t\' then \'graded\' ' +
	      '       when grades.is_student_visible = \'f\' then \'drafted\' ' +
	      '       when grades.is_student_visible is null then \'ungraded\' ' +
	      '  end as grading_status ' +
	      ', assignments.is_team_deliverable ' +
	      ', deliverables.id as deliverable_id ' +
	      ', deliverables.team_id ' +
	      ', deliverables.course_id ' +
	      ', deliverables.assignment_id ' +
	      ', assignments.assignment_order ' +
	      'from teams left outer join deliverables on deliverables.team_id = teams.id ' +
	      '  left outer join team_assignments on teams.id = team_assignments.team_id ' +
	      '  left outer join grades on grades.course_id = deliverables.course_id ' +
	      ' and grades.assignment_id = deliverables.assignment_id ' +
	      ' and team_assignments.user_id = grades.student_id ' +
	      '  left outer join users on users.id = coalesce(teams.primary_faculty_id, '+
	      'teams.secondary_faculty_id) ' +
	      '  left outer join assignments on deliverables.assignment_id = assignments.id ' +
	      ' and assignments.course_id = deliverables.course_id ' +
	      '  left outer join courses on courses.id = deliverables.course_id ' +
	      'where deliverables.course_id = ' + course_id.to_s +
	      'and assignments.is_submittable = \'t\' ' +
	      'and assignments.is_team_deliverable = \'t\' ' + append_where_clause +
	      'order by task_number, assignments.assignment_order, advisor_name, owner_name '
    return sql_query
	end

	def self.get_individual_deliverables_query(course_id, append_where_clause = '')
	  sql_query = 'select courses.name as course_name ' +
	      ', assignments.task_number ' +
	      ', assignments.name as deliverable_name ' +
	      ', stud.human_name as owner_name ' +
	      ', stud_course_team_advisor_view.advisor_name as advisor_name ' +
	      ', case when grades.is_student_visible = \'t\' then \'graded\' ' +
	      '       when grades.is_student_visible = \'f\' then \'drafted\' ' +
	      '       when grades.is_student_visible is null then \'ungraded\'  ' +
	      '  end as grading_status ' +
	      ', assignments.is_team_deliverable ' +
	      ', deliverables.id as deliverable_id ' +
	      ', deliverables.team_id ' +
	      ', deliverables.course_id ' +
	      ', deliverables.assignment_id ' +
	      ', assignments.assignment_order ' +
	      'from users stud left outer join deliverables on deliverables.creator_id = stud.id ' +
	      '  left outer join grades on grades.course_id = deliverables.course_id  ' +
	      '  and grades.assignment_id = deliverables.assignment_id  ' +
	      '  and grades.student_id = stud.id ' +
	      '  left outer join assignments on deliverables.assignment_id = assignments.id  ' +
	      '  and assignments.course_id = deliverables.course_id  ' +
	      '  and assignments.id = grades.assignment_id ' +
	      '  left outer join (select courses.id as course_id, courses.name as course_name ' +
	      '                   , prof.human_name as advisor_name ' +
	      '                   , teams.id as team_id, teams.name as team_name ' +
	      '                   , stud.id as stud_id, stud.human_name as stud_name ' +
	      '                   from users stud join registrations on stud.id = registrations.user_id ' +
	      '                     join courses on courses.id = registrations.course_id ' +
	      '                     join team_assignments on stud.id = team_assignments.user_id ' +
	      '                     join teams on team_assignments.team_id = teams.id ' +
	      '                       and teams.course_id = registrations.course_id ' +
	      '                     join users prof on prof.id = coalesce(teams.primary_faculty_id, teams.secondary_faculty_id)  ' +
	      '                   where stud.is_student = \'t\' ' +
	      '                     and stud.is_staff = \'f\') stud_course_team_advisor_view  ' +
	      '  on stud_course_team_advisor_view.stud_id = stud.id  ' +
	      '  and stud_course_team_advisor_view.course_id = deliverables.course_id ' +
	      '  left outer join courses on courses.id = deliverables.course_id  ' +
	      '  and courses.id = stud_course_team_advisor_view.course_id ' +
	      '  and stud_course_team_advisor_view.course_id = grades.course_id ' +
	      'where deliverables.course_id = ' + course_id.to_s +
	      'and assignments.is_submittable = \'t\' ' +
	      'and assignments.is_team_deliverable = \'f\' ' + append_where_clause +
	      'order by task_number, assignments.assignment_order, advisor_name, owner_name '
    return sql_query
	end
end

# ENum for Team Selection
class TeamSelection
  MY_TEAMS = 1
  ALL_TEAMS = 2
end
