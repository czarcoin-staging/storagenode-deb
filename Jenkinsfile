def withDockerNetwork(Closure inner) {
	try {
		networkId = UUID.randomUUID().toString()
		sh "docker network create ${networkId}"
		inner.call(networkId)
	} finally {
		sh "docker network rm ${networkId}"
	}
}

node {
	stage('Build Package') {
		def builderImage = docker.build("builder-image", "-f docker/Dockerfile.builder .")
		builderImage.inside {
			sh 'cd packaging && dpkg-buildpackage -us -uc -b'
			stash includes: '*.deb', name: 'deb-package'
		}
	}

	stage('Build binaries') {
		def binaries_server = docker.build("binaries-s", "-f ./docker/Dockerfile.binaries .")
		def debian_buster_client = docker.image('debian:buster')
		withDockerNetwork{ n ->
			binaries_server.withRun("--network ${n} --name binaries-server") { c ->
				debian_buster_client.inside("--network ${n} -u root:root") {
					sh "apt-get update"
					sh 'apt-get install -y wget unzip'
	//				sh 'wget http://binaries-server'
					sh 'wget http://binaries-server/index.html'
					sh 'timeout 30s dpkg -i *.deb'
				}
			}
		}
	}

		// TODO
		/*stage('Test Package') {
			agent {
				dockerfile {}
			}
			steps {
				unstash 'deb-package'
			}
		}*/

	stage('Build Repository') {
		def repoBuilderImage = docker.build("repo-builder", "-f ./apt-repository/Dockerfile.reprepro .")
		repoBuilderImage.inside() {
			sh 'git clean -fdx'
			// check reprepro config
			sh "cd apt-repository && reprepro check buster-staging"
			// include new deb
			unstash 'deb-package'
			// for tests, we need to tell reprepro to not sign the packages
			sh 'sed -i \'/SignWith/d\' apt-repository/conf/distributions'
			sh 'cd apt-repository && reprepro includedeb buster-staging ../*.deb'
			}
		}

	stage('Test Repository') {

		def apt_repository = docker.build("apt-nginx", "-f ./apt-repository/nginx/Dockerfile .")
		def debian_buster_client = docker.build("debian-client", "-f ./docker/Dockerfile.debian-buster .")

		withDockerNetwork{ n ->
			apt_repository.withRun("--network ${n} --name apt-repository") { c ->
				debian_buster_client.inside("--network ${n} -u root:root") {
					sh "echo \"deb [trusted=yes] http://apt-repository buster-staging main\" > /etc/apt/sources.list.d/storjlabs.list"
					sh "apt-get update"
					sh "apt-cache search storagenode"
				}
			}
		}
	}
}
