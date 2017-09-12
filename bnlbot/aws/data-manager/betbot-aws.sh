#!/usr/bin/env bash

# Config
##########################################################################
readonly appName="Betbot Data Management"
readonly credFile="./cred"
readonly pyEnv="./py-env/bin/activate"

readonly bucket="nonobet-betbot"
readonly S3DataDir="data"
readonly S3LogDir="log"
readonly S3ConfDir="conf"

readonly localDataDir="./data"
readonly LocalLogDir="./log"
readonly localConfDir="./conf"

readonly logEmailFrom='betbot@nonobet.com'

# Below list with ',' no white space
readonly logEmailTo='ToAddresses=b.f.lundin@gmail.com,joakim@birgerson.com'

# Source credentials if available
if [ -f $credFile ]; then
    source ${credFile}
fi

# Source Python virtual environment
source ${pyEnv}


# Logging via email
##########################################################################

# $1 - Calling function
# $2 - Return code
# $3 - AWS CLI command response
log()
{
    local function=${1}; shift
    local returnCode=${1}; shift
    local commandResponse=${1}; shift

    local ec2InstanceIdUrl="http://169.254.169.254/latest/meta-data/instance-id"
    local ec2InstanceId=""
    local localHostname=""
    local emailSubject="ERROR - ${appName}"
    local emailMessage=""

    ec2InstanceId=$(curl -m 3 -s ${ec2InstanceIdUrl})
    localHostname=$(hostname )

    emailMessage=\
$(cat <<-END
<html>
    <head>
        <style>
           table {
                border-collapse: collapse;
            }
            th, td {
                padding: 5px;
                text-align: left;
            }
        </style>
    <head>
    <body>
        <table border="1">
            <tbody>
                <tr>
                    <th>Metadata</th>
                    <th>Value</th>
                </tr>
                <tr>
                    <td>Application</td>
                    <td>${appName}</td>
                </tr>
                <tr>
                    <td>Time</td>
                    <td>$(date)</td>
                </tr>
                <tr>
                    <td>Failed function</td>
                    <td>${function}</td>
                </tr>
                <tr>
                    <td>Error code</td>
                    <td>
                        ${returnCode} (see <a href=
                "http://docs.aws.amazon.com/cli/latest/topic/return-codes.html"
                        >Amazon</a> for more information)
                    </td>
                </tr>
                <tr>
                    <td>Command response</td>
                    <td>${commandResponse}</td>
                </tr>
                <tr>
                    <td>EC2 instance ID</td>
                    <td>${ec2InstanceId}</td>
                </tr>
                <tr>
                    <td>Local hostname</td>
                    <td>${localHostname}</td>
                </tr>
            </tbody>
        </table>
    </body>
</html>
END
)

    aws ses send-email \
        --from "${logEmailFrom}" \
        --destination "${logEmailTo}" \
        --message \
            "Subject={Data=${emailSubject},Charset=utf8},\
            Body={Html={Data='${emailMessage}',Charset=utf8}}"
}


# Low level CLI API examples
##########################################################################

# Docs
# http://docs.aws.amazon.com/cli/latest/reference/s3api/list-buckets.html
# http://docs.aws.amazon.com/cli/latest/reference/s3api/list-objects-v2.html

# AWS API CLI output formats
# http://docs.aws.amazon.com/cli/latest/userguide/controlling-output.html
apiOutputFormat="table"

listBucketsApi()
{
    aws s3api list-buckets --output ${apiOutputFormat} --query "Buckets[].Name"
}

listFilesApi()
{
    aws s3api list-objects-v2 --output ${apiOutputFormat} --bucket ${bucket} \
        --query "Contents[].Key" --prefix ${bucket}
}


# High level CLI test commands
##########################################################################

# Docs
# http://docs.aws.amazon.com/cli/latest/userguide/using-s3-commands.html

testListBuckets()
{
    aws s3 ls 2>&1
}

testListFiles()
{
    aws s3 ls s3://${bucket} 2>&1
}

testSendEmail()
{
    aws ses send-email \
            --from "${logEmailFrom}" \
            --destination "${logEmailTo}" \
            --message \
                "Subject={Data=\"TEST - ${emailSubject}\",Charset=utf8},\
                Body={Text={Data='Test data',Charset=utf8}}"
}


# High level CLI commands
##########################################################################

# Docs
# http://docs.aws.amazon.com/cli/latest/userguide/using-s3-commands.html
# https://aws.amazon.com/s3/storage-classes/

# $1 - AWS command
# $2 - Calling function
runCommand()
{
    local awsCommand="${1}"; shift
    local callingFunc="${1}"; shift
    #local response=""
    local response=""
    response=$(${awsCommand} 2>&1)
    retCode=${?}

    echo ${response}
    echo ${retCode}

    if [ ${retCode} -ne 0 ]; then
        log "${callingFunc}" "${retCode}" "${response}"
    fi
}

syncDataLocalToS3()
{
    local command=""
    command+="aws s3 sync ${localDataDir} s3://${bucket}/${S3DataDir}"
    command+=" --storage-class STANDARD_IA"
    #aws s3 sync ${localDataDir} s3://${bucket}/${S3DataDir} \
    runCommand "${command}" "${FUNCNAME[0]}"
}

syncDataS3ToLocal()
{
    local user="${1}"
    aws s3 sync s3://${bucket}/${S3DataDir}/${user} ${localDataDir}/${user}
}

syncLogLocalToS3()
{
    local user="${1}"
    aws s3 sync ${LocalLogDir}/${user} s3://${bucket}/${S3LogDir}/${user} \
        --storage-class STANDARD_IA
}

syncLogS3ToLocal()
{
    local user="${1}"
    aws s3 sync s3://${bucket}/${S3LogDir}/${user} ${LocalLogDir}/${user}
}

syncConfigLocalToS3()
{
    local user="${1}"
    aws s3 sync ${localConfDir}/${user} s3://${bucket}/${S3ConfDir}/${user}
}

syncConfigS3ToLocal()
{
    local user="${1}"
    aws s3 sync s3://${bucket}/${S3ConfDir}/${user} ${localConfDir}/${user}
}



