# Systems Engineering Laboratory (SELab)

Welcome to SELab! This is a laboratory environment that uses two dockerfiles; `dockerfile.tljh` for installing the littlest jupyter hub (tljh), and `dockerfile.api` for installing the sysmlv2 API server. Our TLJH setup includes the SysML v2 kernel, and this kernel is modified to point to the SysML v2 API server. 

## Quick Start

To start the services, run `start.sh` script in the root directory:

```sh
./start.sh
```

This will initialize the Docker services, create necessary network configurations and volumes, install the Littlest JupyterHub, including the tljh-shared-directory plugin, and prepare additional conda environments defined by the YAML files placed in the `envs` directory.

Before running the `start.sh` script, ensure that it has the necessary execution permissions. If you are using a Linux-based system, you can do this by running the following command in your terminal:

```sh
chmod +x start.sh
```

**Note**: If you get a 'Permission Denied' error when running the `start.sh` script, it is likely because you haven't set the script as executable. Please make sure to run the `chmod` command above.

After that, the script installs `nb_conda_kernels` and creates Jupyter kernels for each Conda environment created. 

## Adding new environments

If you want to create a new environment, place your environment's YAML file into the `envs` directory. The script will detect the new file and build the environment automatically.

## Updating Base Environment

If you want to add new Python packages to the base environment of the JupyterHub, you can do so by adding them to the `requirements.txt` file located in the `envs` directory.

After updating the `requirements.txt` file, you can rerun the `start.sh` script to install the newly added packages in the base environment.

**Note**: Make sure that each package is on a new line in the `requirements.txt` file and the package names are spelled correctly. Also, remember to specify the exact version of the package if needed. For example:

```txt
numpy==1.21.0
scipy==1.7.0
pandas
```

In the example above, the specific versions for numpy and scipy are defined whereas the latest version of pandas will be installed.

## Accessing the services

Wait for several minutes while the services start. Once ready:

- Access the SysML Server: [http://localhost:9000/docs/](http://localhost:9000/docs/)
- Access the Jupyter Lab: [http://localhost:8889/selab/](http://localhost:8889/selab/) 

Log in using `admin:admin` credentials. If you see a 404 error, try starting and stopping the server. If the error persists, rerun `start.sh` to refresh the TLJH installation. The second run is significantly faster than the initial build.

Tip: During the first load of the sysml API server on port 9000 it may take several minutes for the server to build. You actually have to hit the URL for the server to build so after the install is complete just hit the localhost:9000 URL and wait when its complete you will see --> Welcome to SysML 2.0 REST API implementation!

## Configurations

A config file for TLJH is located in the `config` directory. This is where you can set the `base_url` (defaulted to `selab` in this install), memory, and CPU limits.

## Sample Notebooks

If you'd like to pull in sample files to your Jupyter Lab, you can do so by clicking the links below:

- [SELab Notebooks](http://localhost:8889/selab/hub/user-redirect/git-pull?repo=https%3A%2F%2Fgithub.com%2Fenginetix2%2Fselab_notebooks.git&urlpath=lab%2Ftree%2Fselab_notebooks.git%2FREADME.md&branch=main)

- [SysML v2 Applications and Examples](http://localhost:8889/selab/hub/user-redirect/git-pull?repo=https%3A%2F%2Fgithub.com%2FOpen-MBEE%2FSysML-v2-Applications-and-Examples&urlpath=lab%2Ftree%2FSysML-v2-Applications-and-Examples%2FJupyter-SysML+v2.ipynb&branch=main)

These links will automatically clone the repositories and open the README files or notebooks in your current Jupyter Lab environment. If you want to refresh the content from these repositories, simply click the link again.

## Troubleshooting

In case of a persistent 404 error after launching Jupyter Lab, follow these steps:

1. Stop and start the server.
2. If the issue persists, rerun the `start.sh` script. (Somthing is breaking during the current install and the update fixes it...)
3. If the issue is still not resolved, please reach out for further support.

Remember, subsequent runs of `start.sh` are much quicker than the initial build, so this shouldn't take too much time.

## Feedback and Contributions

We welcome your feedback and contributions to enhance SELab. Please open an issue or a pull request if you have suggestions for improvements or have identified any bugs. 

## License

SELab is released under the [MIT License](./LICENSE).
