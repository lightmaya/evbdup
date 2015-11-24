# -*- encoding : utf-8 -*-
class DepartmentsController < JamesController
  def show
    return redirect_to(not_found_path) unless @dep = Department.valid.find_by_id(params[:id])
  end
end
