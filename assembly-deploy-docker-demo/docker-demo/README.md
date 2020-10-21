# 使用步骤

**单纯docker部署， 不包含打包**

步骤如下：

- 先打包springboot基础镜像，openjdk8:sunyard(如果已有，可以省略此步骤)

- pom.xml引入docker打包脚本

- 执行mvn clean  package

   or

- 执行到dockerCompose目录，执行docker-compose

工程结构说明：

```bash
docker-demo
    src
        assembly(打包所有脚本)
            basicImage(信雅达springboot基础镜像，主要有jdk、bash、unzip等)
            bin(程序启动脚本，包含了start.sh和shutdown.sh--基本不用改)
            docker(程序的docker镜像打包脚本--基本不用改)
            dockerCompose(docker-compose.yml存放的地址)
        main(程序所在)
            java
            resources
    pom.xml
```
