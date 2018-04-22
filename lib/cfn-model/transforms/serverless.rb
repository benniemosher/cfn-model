class CfnModel
  class Transforms
    # Handle transformation of model elements performed by the
    # Serverless trasnform, see
    # https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-serverless.html
    class Serverless
      def perform_transform(cfn_hash)
        new_hash = cfn_hash.dup
        cfn_hash['Resources'].each do |r_name, r_value|
          next unless r_value['Type'].eql? 'AWS::Serverless::Function'
          replace_serverless_function new_hash, r_name
        end
        cfn_hash = new_hash
      end

      def self.instance
        if @instance.nil?
          @instance = TransformRegistry.new
        end
        @instance
      end

      private

      def replace_serverless_function(cfn_hash, resource_name)
        # Bucket is 3rd element of an S3 URI split on '/'
        code_bucket = \
          cfn_hash[resource_name]['Properties']['CodeUri'].split('/')[2]
        # Object key is 4th element to end of an S3 URI split on '/'
        code_key = \
          cfn_hash[resource_name]['Properties']['CodeUri']
            .split('/')[3..-1].join('/')

        cfn_hash.merge!(
          lambda_function(
            handler: cfn_hash[resource_name]['Properties']['Handler'],
            code_bucket: code_bucket,
            code_key: code_key,
            runtime: cfn_hash[resource_name]['Properties']['Runtime']
          )
        )

        cfn_hash.merge!(
          function_name_role
        )
      end

      # Return the hash structure of the 'FunctionNameRole'
      # AWS::IAM::Role resource as created by Serverless transform
      def function_name_role
        { 'FunctionNameRole' => {
            'Type' => 'AWS::IAM::Role',
            'Properties' => {
              'ManagedPolicyArns' =>
              ['arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'],
              'AssumeRolePolicyDocument' => {
                'Version' => '2012-10-17',
                'Statement' => [{
                  'Action' => ['sts:AssumeRole'],
                  'Effect' => 'Allow',
                  'Principal' => {
                    'Service' => ['lambda.amazonaws.com']
                  }
                }]
              }
            }
          } }
      end

      # Return the hash structure of a AWS::Lambda::Function as created
      # by Serverless transform
      def lambda_function(handler:, code_bucket:, code_key:, runtime:)
        {
          'Type' => 'AWS::Lambda::Function',
          'Properties' => {
            'Handler' => handler,
            'Code' => {
              'S3Bucket' => code_bucket,
              'S3Key' => code_key
            },
            'Role' => {
              'Fn::GetAtt' => ['FunctionNameRole', 'Arn']
            },
            'Runtime' => runtime
          }
        }
      end
    end
  end
end
