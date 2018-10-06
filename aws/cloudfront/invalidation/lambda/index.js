'use strict';
var AWS = require("aws-sdk");
var cloudfront = new AWS.CloudFront();
var sqs = new AWS.SQS({region: process.env.AWS_REGION});

const NUM_OF_RETRIES = process.env.INVALIDATION_MAX_RETRIES;
var RETRY_TIMOUT = process.env.INVALIDATION_RETRY_TIMOUT

exports.handler = (event, context, callback) => {
    var record = event.Records[0];
    var body = JSON.parse(record.body)
    var message = JSON.parse(body.Message);

    console.info("SQS Message: ", message);
    
    if (!message.distribution_id || !message.path) {
        var msg = `[WARNING] bad format. desired SNS message format: {\"distribution_id\": \"<distid>\", \"path\": \"/a/path/*\"}`;
        console.log(msg);
        callback(null, msg);
        return;
    }

    var invalidationParams = {
        DistributionId: message.distribution_id,
        InvalidationBatch: {
            CallerReference: new Date().getTime().toString(),
            Paths: {
                Quantity: 1,
                Items: [message.path]
            }
        }
    };

    cloudfront.createInvalidation(invalidationParams, function (err, data) {
        if (err) {
    
            if (err.code !== 'TooManyInvalidationsInProgress') {
                var msg = `[WARNING] ignoring error: ${err}.`;
                console.log(msg);
                callback(null, msg);
                return;
            }
            
            var retried =  message.retry_count | 0;
            if (retried > NUM_OF_RETRIES-1) {
                var msg = `[WARNING] Failed after ${NUM_OF_RETRIES} retries`;
                console.log(msg);
                callback(null, msg);
                return;
    
    		} else {
    			retried++;
    			message.retry_count = retried;
    			
    			var arn = record.eventSourceARN.split(':', 6);
                var queueUrl = 'https://sqs.'+ arn[3] +'.amazonaws.com/'+ arn[4] +'/'+ arn[5];

                // This Message must be in SNS => SQS Format for incoming parsing to work
    			var params = {
    				MessageBody: JSON.stringify({Message: JSON.stringify(message)}),
    				QueueUrl: queueUrl,
    				DelaySeconds: RETRY_TIMOUT
    			};
			    var msg = `[RETRY] retrying ${invalidationParams.DistributionId}:${invalidationParams.Paths}`
	    		console.log(params)

    			sqs.sendMessage(params, function (err, data) {
    				if (err) {
    					console.log(err);
    					callback("failed to send message for retry");
    				} else {
    	                var msg = `[RETRY] Scheduling a retry in ${RETRY_TIMOUT} seconds. ${retried} retries`;
                        console.log(msg);
                        callback(null, msg);
                        return;
    				}
    			});
            }
            
        }
        else
            console.log(data);
    });

    callback(null, 'A-OK');    
};
