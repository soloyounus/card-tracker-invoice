class InvoicerChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'invoicer:generate'

    transmit({
      action: :init,
      payload: jobs()
        # .sort_by { |k| k['jobId'] }
        # .reject { |j| j[:status].nil? }
    })
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def jobs
    records = Delayed::Job.all
    records.load
    records.to_a.map do |j|
      data = j.payload_object.job_data
      jst = ActiveJobStatus.fetch(data['job_id'])

      {
        jobId: data['job_id'],
        args: data['arguments'][0],
        status: jst.status,
      }
    end
  end
end
