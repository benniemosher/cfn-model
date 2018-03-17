require_relative 'model_element'

class AWS::S3::BucketPolicy  < ModelElement
  # mapped from document
  attr_accessor :bucket, :policyDocument

  # PolicyDocument - objectified policyDocument
  attr_accessor :policy_document

  def initialize(cfn_model)
    super
    @resource_type = 'AWS::S3::BucketPolicy'
  end
end
