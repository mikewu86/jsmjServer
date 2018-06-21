#!groovy
properties([[$class: 'ParametersDefinitionProperty', parameterDefinitions: [[$class: 'BooleanParameterDefinition', name: 'autoDeploy', defaultValue: false, description: '是否立即部署到服务器？'], [$class: 'StringParameterDefinition', name: 'rancherProject', defaultValue: 'server22', description: 'rancher中项目名'], [$class: 'StringParameterDefinition', name: 'deployServers', defaultValue: '', description: '需要部署的服务器列表,多个游戏以逗号分隔']]], [$class: 'GitLabConnectionProperty', gitLabConnection: 'gitlab_uc888']])

node('dockerhost') {
   // Mark the code checkout 'stage'....
    //echo "received autoDeploy ${binding.hasVariable('autoDeploy') ? autoDeploy : 'undefined'}"
    //echo "received rancherProject ${binding.hasVariable('rancherProject') ? rancherProject : 'undefined'}"
    //echo "received deployServers ${binding.hasVariable('deployServers') ? deployServers : 'undefined'}"

    def bAutoDeploy = false
    def allServers = ['texas', 'nanjingmj', 'suzhoumj', 'hefeimj', 'wuhumj', 'ddz3', 'xinghuamj', 'maanshanmj']
    def deployAllServer = false
    def strDeployServers = params.deployServers ?: ''

    echo "autoDeploy ${autoDeploy}"
    echo "rancherProject ${rancherProject}"
    echo "deployServers ${deployServers}"
    echo "${params.deployServers ?: ''}"

    //if (bAutoDeploy == true && strDeployServers == '') {
    if (autoDeploy == 'true' && strDeployServers == '') {
        echo 'deployServers is empty'
    }

    if (strDeployServers == 'all') {
        deployAllServer = true
    }

    def pppp = strDeployServers.tokenize(',')
    echo "pppp is ${pppp}"

    if (autoDeploy == 'true') {
        bAutoDeploy = true
        echo 'autoDeploy == true'
        if(deployAllServer == false) {
            if(pppp.size() < 1) {
                error 'deployServers is empty'
            }
        }
    }

    def composePath = 'compose/' + env.BRANCH_NAME
    stage('Checkout'){
        checkout scm
        //def v = gitRevision()
        def v = gitTagNum()
        if (v) {
            echo "Building version ${v}"
        }
        env.dockerTag = env.BRANCH_NAME + '-' + v
        
        echo "Docker Tag is ${env.dockerTag}"
        env.IMAGE_TAG = env.dockerTag
    }

    // Mark the code build 'stage'....
    stage('LuaLint'){
        gitlabCommitStatus('LuaLint') {
            sh 'python tests/luatest.py'
        }
    }

    stage('Build'){
        gitlabCommitStatus('Build') {
            // Run the docker build
            docker.withRegistry('https://dockerhub.ucop.io', '71830978-aa7b-45f6-b9b5-ec82ff55f4b4') {
                // some block
                if (env.BRANCH_NAME == 'master') {
                    docker.build('mobile/mgserver-release').push(env.dockerTag)
                }
                else {
                    docker.build('mobile/mgserver').push(env.dockerTag)
                }
            }
        }
    }

    /*
    stage('TestContainerState'){
        if (deployAllServer == false) {
            def ret = sh(returnStdout: true, script: 'python tests/rancher_container_status.py ' + pppp).trim()
            pppp = ret.tokenize(',')
            echo "pppp after TestContainerState is ${pppp}"
        }
        else {
            def ret = sh(returnStdout: true, script: 'python tests/rancher_container_status.py ' + allServers).trim()
            allServers = ret.tokenize(',')
        }
    }
    */
    
    
    
    stage('DeployPlatform'){
        if (bAutoDeploy == true) {
            dir(composePath) {
                if (deployAllServer == true || pppp.contains("platform") == true) {
                    runRancherCompose(rancherProject, 'compose-platform.yml', false)
                }
                
                //sh 'rancher-compose -p ' + rancherProject + ' -f compose-platform.yml up -d --force-recreate -c'
            }
        }
        else {
            echo 'not deploy!'
        }
    }
    
    

    stage('DeployGameServer'){
        if (bAutoDeploy == true) {
            dir(composePath) {
                def stepsForParallel = [:]
                if (deployAllServer == false) {
                    for (int i = 0; i < pppp.size(); i++) {
                        def s = pppp.get(i)
                        def stepName = "rancher ${s}"
                        
                        stepsForParallel[stepName] = runRancherCompose(rancherProject, 'compose-' + s + '.yml', true)
                    }
                }
                else {
                    for (int i = 0; i < allServers.size(); i++) {
                        def s = allServers.get(i)
                        def stepName = "rancher ${s}"
                        
                        stepsForParallel[stepName] = runRancherCompose(rancherProject, 'compose-' + s + '.yml', true)
                    }
                }
                

                parallel stepsForParallel
                /*
                parallel 'texas': {
                    runRancherCompose(rancherProject, 'compose-texas.yml')
                    //sh 'rancher-compose -p ' + rancherProject + ' -f compose-texas.yml up -d --force-recreate -c'
                }, 'nanjingmj': {
                    runRancherCompose(rancherProject, 'compose-nanjingmj.yml')
                    //sh 'rancher-compose -p ' + rancherProject + ' -f compose-nanjingmj.yml up -d --force-recreate -c'
                }*/
            }
        }
        else {
            echo 'not deploy!'
        }
    }

}

def runRancherCompose(rancherProj, composeFile, isParallel) {
    def rancherUrl = 'http://rancher.ucop.io:8080/'
    def rancherAccessKey = '307FFBC01CBDD23822D9'
    def rancherSecretKey = '2kCX6dWgKZcM7EKfyGNtbdKsXfJSfP8hEGvqbwAh'
    if (env.BRANCH_NAME == 'master') {
        //rancherAccessKey = '6285F4C595286D83827E'
        //rancherSecretKey = 'FY4GvULbxhZZTaSf6VQchCtxuxsNfxuUAJEdeMhT'
    }

    if (isParallel == true) {
      return {
          gitlabCommitStatus('Deploy') {
            withEnv(['RANCHER_URL=' + rancherUrl, 'RANCHER_ACCESS_KEY=' + rancherAccessKey, 'RANCHER_SECRET_KEY=' + rancherSecretKey]) {
                //sh '$MYTOOL_HOME/bin/start'
                sh 'rancher-compose -p ' + rancherProj + ' -f ' + composeFile + ' up -d --force-recreate -c'
            }
          }

    }
    }
    else {
        gitlabCommitStatus('Deploy') {
            withEnv(['RANCHER_URL=' + rancherUrl, 'RANCHER_ACCESS_KEY=' + rancherAccessKey, 'RANCHER_SECRET_KEY=' + rancherSecretKey]) {
                //sh '$MYTOOL_HOME/bin/start'
                sh 'rancher-compose -p ' + rancherProj + ' -f ' + composeFile + ' up -d --force-recreate -c'
            }
        }
      
    }

    
    
}

def gitTagNum() {
    def gitCommit = sh(returnStdout: true, script: 'git tag --sort version:refname | tail -1').trim()
    while (gitCommit.size() > 10) {
        echo "before:gitCommit ${gitCommit}"
        sh 'git tag -d ' + gitCommit
        gitCommit = sh(returnStdout: true, script: 'git tag --sort version:refname | tail -1').trim()
        echo "after del:gitCommit ${gitCommit}"
    }
    gitCommit.take(10)
}

def gitRevision() {
    def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
    gitCommit.take(6)
}