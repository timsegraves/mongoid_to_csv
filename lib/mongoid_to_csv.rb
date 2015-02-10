require 'mongoid'
require 'csv'

module MongoidToCSV

  # Return full CSV content with headers as string.
  # Defined as class method which will have chained scopes applied.
  def to_csv(exclude_fields=true)
    documents_to_csv(all, fields, exclude_fields)
  end

  module_function

  def documents_to_csv(documents, fields = documents.first.class.fields, exclude_fields=true)
    doc_class = documents.first.class
    csv_columns = fields.keys 
    csv_columns = csv_columns - %w{_id created_at updated_at _type} if exclude_fields
    header_row = csv_columns.to_csv
    records_rows = documents.map do |record|
      csv_columns.map do |column|
        value = record.send(column)
        value = value.to_csv if value.respond_to?(:to_csv)
        value
      end.to_csv
    end.join
    header_row + records_rows
  end

end

module Mongoid::Document
  def self.included(target)
    target.extend MongoidToCSV
  end
end

# Define Relation#to_csv so that method_missing will not
# delegate to array.
class Mongoid::Relation
  def to_csv
    scoping do
      @klass.to_csv
    end
  end
end

class Array
  def mongoid_to_csv(exclude_fields=true)
    return self if empty?
    MongoidToCSV.documents_to_csv(self, exclude_fields)
  end
end
