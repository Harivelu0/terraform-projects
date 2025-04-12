# Jenkins with Docker Setup Guide

This guide walks through setting up Jenkins in a Docker container with the ability to build Docker images.

## 1. Run Jenkins Container with Docker Socket

Start a Jenkins container with the Docker socket mounted:

```bash
docker run -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts 
```

## 2. Fix Docker Socket Permissions

On the host machine, update the Docker socket permissions:

```bash
sudo chmod 666 /var/run/docker.sock
```

## 3. Get Jenkins Admin Password

Retrieve the initial Jenkins admin password:

```bash
docker exec ${CONTAINER_ID} cat /var/jenkins_home/secrets/initialAdminPassword
```

## 4. Install Docker CLI Inside Jenkins Container

Connect to the Jenkins container as root and install Docker CLI:

```bash
# Log in as root
docker exec -it -u root ${CONTAINER_ID} bash

# Install Docker CLI
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce-cli

# Add Jenkins user to the docker group
groupadd -f docker
usermod -aG docker jenkins

# Exit container
exit
```

## 5. Restart Jenkins Container

Restart the container to apply group changes:

```bash
docker restart ${CONTAINER_ID}
```

## 6. Jenkins Configuration

### 6.1 Install Required Plugins

Go to "Manage Jenkins" > "Manage Plugins" and install:
- NodeJS Plugin
- Docker Pipeline Plugin

### 6.2 Configure NodeJS

Go to "Manage Jenkins" > "Tools" and:
- Enable NodeJS
- Add NodeJS installation with version 18.17 or higher

### 6.3 Set Up Credentials

Go to "Manage Jenkins" > "Manage Credentials" and add these credentials as "Secret text":

- `DATABASE_URL_CREDENTIAL`: Your PostgreSQL Neon database URL
- `CLERK_SECRET_KEY_CREDENTIAL`: Your Clerk secret key
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY_CREDENTIAL`: Your Clerk publishable key
- `DOCKER_CREDENTIALS`: Your Docker Hub credentials (Username with password)

## 7. Verify Docker Works Inside Jenkins

Connect to the Jenkins container and verify Docker works:

```bash
docker exec -it ${CONTAINER_ID} bash
docker ps
```

You should see a list of running containers, confirming that Docker commands can be executed from inside the Jenkins container.

## 8. Run Your Pipeline

Create a new Pipeline job or run an existing one that uses Docker commands. The pipeline should now successfully build and push Docker images.