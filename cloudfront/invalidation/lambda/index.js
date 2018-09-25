
exports.handler = (event, context, callback) => {
    event.Records.forEach((record) => {
        console.info("SQS Message: ", JSON.stringify(record, null, 2))
    });
    callback(null, `Successfully processed ${event.Records.length} records.`);
};
