require 'pathname'

class ReportsController < ApplicationController
  def show
    report = Report.find_by job_id: params[:id]

    if report
      if report.file.attached?
        redirect_to(url_for(report.file))
      else
        return render json: {error: "cannot find report attachments", status: 500}.to_json
      end
    else
      return render json: {error: "cannot find report", status: 500}.to_json
    end
  end
end
