class CreateReports < ActiveRecord::Migration[5.2]
  def change
    create_table :reports do |t|
      t.string :job_id
      t.string :job_args

      t.timestamps
    end
    add_index :reports, :job_id, unique: true
  end
end
