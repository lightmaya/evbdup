# -*- encoding : utf-8 -*-
class DepartmentsController < JamesController
  def show
    return redirect_to(errors_path(no: 404)) unless @dep = Department.valid.find_by_id(params[:id])
  end
end
