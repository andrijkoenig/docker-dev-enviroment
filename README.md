# 🛠 My Dev Environment (Docker)

A containerized Neovim setup for a consistent, plugin-rich development environment.

## 🚀 Quick Start

### Build the image
```bash
docker build -t andrijkoenig/dev-env .
```

### Pull the image 
```bash
docker pull andrijkoenig/dev-env:latest
```

### Run the image with the current path mounted (windows)
```bash
docker run -it --rm -v $pwd/:/home/devuser/project -p 4200:4200 andrijkoenig/dev-env:latest
```

---
Usefull powershell alias to run the image in the current path
```powershell
function RunDockerEnvironment {
    param(
        [string[]]$Ports
    )

	$PemFilePath = "PUT_PATH_HERE"

    # Determine container runtime
    $containerCmd = if (Get-Command docker -ErrorAction SilentlyContinue) {
        "docker"
    } elseif (Get-Command podman -ErrorAction SilentlyContinue) {
        "podman"
    } else {
        Write-Error "Neither Docker nor Podman is installed."
        return
    }

    # Base Docker args
    $argsList = @(
        "run"
        "-it"
        "--rm"
        "-v", "$pwd/:/home/devuser/project"
    )
	
	if ($PemFilePath) {
		if (-Not (Test-Path $PemFilePath)) {
			Write-Error "Provided PEM file does not exist: $PemFilePath"
			return
		}

		# Mount the PEM file into a known path inside the container
		$resolvedPemPath = Resolve-Path $PemFilePath
		$argsList += "-v"
		$argsList += "${resolvedPemPath}:/tmp/cert.pem"
	}
	
    # Add -p args if ports provided
    if ($Ports -and $Ports.Count -gt 0) {
        foreach ($port in $Ports) {
            if ($port -match '^\d+$') {
                $argsList += "-p"
                $argsList += "$port`:$port"
            } else {
                $argsList += "-p"
                $argsList += $port
            }
        }
    }

    # Append image name
    $argsList += "andrijkoenig/dev-env:latest"

    # Run container
    & $containerCmd @argsList
}

Set-Alias rde RunDockerEnvironment

```

--- 

New simpler nightly version:

1. Place this file somewhere on your PATH (e.g. C:\Users\<you>\bin\nvim.ps1):
```
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    $Args
)

# The image name you built
$image = "andrijkoenig/dev-env:nightly"

# Run Neovim container as if it were native
docker run --rm -it `
    -v "${PWD}:/workspace" `
    -v "$env:USERPROFILE\.config\nvim:/root/.config/nvim" `
    -w /workspace `
    $image @Args
``` 

and in the $PROFILE

` Set-Alias nvim "C:\Users\<you>\bin\nvim.ps1" ` 

