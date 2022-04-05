#!/usr/bin/env node
const fs=require('fs');

const split='##CONFIG##';

const config=require(`${__dirname}/gc-config.json`)
const connName=`${config.GC_PROJECT_ID}:${config.GC_REGION}:${config.DATABASE_SERVER_INSTANCE}`;
config.DATABASE_CONNECTION=connName;
config.DATABASE_HOST=`/cloudsql/${connName}`;

const deployYamlPath=`${__dirname}/.github/workflows/deploy.yml`
const parts=fs.readFileSync(deployYamlPath).toString().split(split);

if(parts.length===5){
  let appVars='\n';
  let envVars='\n';
  for(const e in config){
    appVars+=`  G_${e}: ${config[e]}\n`
    envVars+=`          echo '${e}=${config[e]}' >> .env\n`
  }
  envVars+='          ';
  parts[1]=appVars;
  parts[3]=envVars;
  fs.writeFileSync(deployYamlPath,parts.join(split));
  console.log(`app vars written to: ${deployYamlPath}`);
}else{
  console.error('5 segments expected separated by ##CONFIG##');
}



