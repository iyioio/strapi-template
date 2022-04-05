module.exports =  ({ env }) => {
  const config={};

  const bucket=env('BUCKET_NAME');
  if(bucket){
    config.upload={
      config: {
        provider: 'strapi-provider-upload-google-cloud-storage',
        providerOptions: {
            bucketName: bucket,
            publicFiles: true,
            uniform: false,
            basePath: '',
        },
      },
    }
  }

  const emailFrom=env('EMAIL_FROM');
  const emailReplyTo=env('EMAIL_REPLY_TO',emailFrom);
  const sendGridKey=env('SENDGRID_API_KEY');
  if(sendGridKey && emailFrom){
    config.email={
      config:{
        provider: 'sendgrid',
        providerOptions: {
          apiKey: sendGridKey,
        },
        settings: {
          defaultFrom: emailFrom,
          defaultReplyTo: emailReplyTo,
        },
      }
    }
  }


  return config;
}
