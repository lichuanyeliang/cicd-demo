# 使用步骤

单纯打包，不包含docker容器

```bash
scp xxx.tar.gz root@ip:/$path #上传
cd ${target} ##${target} #表示你上传xxx.tar.gz的目录
mkdir -p xxx
cd xxx/bin
./startup.sh

```
