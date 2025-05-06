# Set variables
$ProjectPath = "C:\Users\$Env:UserName\projects"
$ImageName = "dev-env-nvim"

# Run the Docker container
docker run -it --rm `
    -v "${ProjectPath}:/home/devuser/workspace" `
    -p 4200:4200 `
    -p 8080:8080 `
    -p 5000:5000 `
    $ImageName
