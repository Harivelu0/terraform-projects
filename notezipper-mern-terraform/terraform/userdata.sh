#!/bin/bash

# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script execution..."

# Update system and install basic utilities
echo "Updating system packages..."
sudo yum update -y
sudo yum install -y git curl

# Install Node.js 16.x
echo "Installing Node.js..."
curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
sudo yum install -y nodejs

# Verify installations
echo "Verifying installations..."
node --version
npm --version
git --version

# Create app directory with proper permissions
echo "Setting up application directory..."
sudo mkdir -p /home/ec2-user/app
sudo chown ec2-user:ec2-user /home/ec2-user/app
cd /home/ec2-user/app

# Clone repository
echo "Cloning repository..."
git clone https://github.com/piyush-eon/notezipper.git .

# Install backend dependencies
echo "Installing backend dependencies..."
npm install

# Setup frontend
echo "Setting up frontend..."
cd frontend
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
npm install postcss@8.4.31 --save-exact
npm install postcss-safe-parser@6.0.0 --save-exact

# Return to app root
cd ..

# Create environment file
echo "Creating environment file..."
cat > .env << EOL
PORT=5000
MONGO_URI=mongodb+srv://hpvp24:GSivthIwinRk3GfQ@cluster0.yyunm.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
NODE_ENV=production
JWT_SECRET=hari1234
EOL

# Install PM2 globally
echo "Installing PM2..."
sudo npm install -g pm2

# Build frontend
echo "Building frontend..."
cd frontend
npm run build
cd ..

# Start applications with PM2
echo "Starting applications with PM2..."
# Start backend
pm2 start backend/server.js --name notezipper-backend

# Serve frontend build with a static server
sudo npm install -g serve
pm2 start serve --name notezipper-frontend -- -s frontend/build -l 3000

# Save PM2 configuration and setup startup script
echo "Configuring PM2 startup..."
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

echo "User data script execution completed!"