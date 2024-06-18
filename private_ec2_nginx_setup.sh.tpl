#!/bin/bash
sudo yum update -y
sudo yum install -y nginx
sudo bash -c 'cat > /usr/share/nginx/html/index.html << "EOL"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Private Instance Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f0f0f0; margin: 0; padding: 0; }
        .container { max-width: 800px; margin: 50px auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        p { color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from the Private Instance</h1>
        <p>This is a simple web page served from the private instance.</p>
    </div>
</body>
</html>
EOL'
sudo systemctl start nginx
sudo systemctl enable nginx