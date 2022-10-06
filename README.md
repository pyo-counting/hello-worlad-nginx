# NGINX
NGINX 오픈소스 기반 reverse proxy & load balancer 프로젝트

## 프로젝트 구성
- 프로젝트 구조

    ``` bash
    .
    ├── conf
    │   ├── cert
    │   │   └── ${CONF}
    │   │       └── *.crt, *.key 파일
    │   ├── conf.d
    │   │   ├── default.conf
    │   │   └── ${CONF}.conf
    │   └── nginx.conf
    ├── docker-compose.yml
    ├── init_script
    │   └── init.sh.template
    └── run.sh
    ```
**./run.sh** 쉘 스크립트를 실행해 nginx docker container를 배포 및 종료한다. 배포 환경에 따른 nginx 설정 파일을 container 내부에 mount하기 위해 **./run.sh** 쉘 스크립트 실행 시 파라미터를 사용한다.

- nginx 설정 파일
    - `conf/nginx.conf`: 공통 설정
    - `conf/conf.d/default.conf`: health check, Prometheus URL 설정
    - `conf/conf.d/*.conf`: reverse proxy 관련 설정
## 배포하기
- GitLab CI/CD 이용
    >**Note:** GitLab CI/CD를 이용해 배포하기 위해서는 **./gitlab-ci.yml**파일에 deploy stage도 작성이 필요하다.

- 수동 배포
    1. git project clone

        ``` bash
        git clone https://gitlab.danal.co.kr/fs-solution/nginx.git
        ```
    2. 프로젝트 디렉토리로 이동
        ``` bash
        cd nginx
        ```
    3. 실행
        ``` bash
        # 메뉴얼
        ./run.sh help
        Usage: run.sh start|stop|help

                start CONF                Start nginx container
                stop CONF                 Stop nginx container
                restart CONF              Stop and start nginx container
                help                      Show usage

        # CONF=obp 파라미터 사용해 쉘 스크립트 실행
        ./run.sh start obp

        Check whether ./conf/conf.d/obp.conf file exist
        ------------------------------------------------------------

        Make ./init_script/init.sh from ./init_script/init.sh.template
        ----------------------------------------------------------------

        Start nginx container (CONF=obp)
        Worker process owned by uid=3001(wasd), gid=3000(operators)
        ----------------------------------------------------------------
        [+] Running 1/1
        ⠿ Container nginx-reverse-proxy  Started 

        # 정상 실행 확인하기
        docker compose ps -a
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        NAME                  COMMAND                  SERVICE             STATUS              PORTS
        nginx-reverse-proxy   "/docker-entrypoint.…"   nginx               running (healthy)
        ```
    4. 종료
        ``` bash
        # 종료
        ./run.sh stop obp
        
        Check whether ./conf/conf.d/obp.conf file exist
        ------------------------------------------------------------
        
        Stop nginx container (CONF=obp)
        ----------------------------------------------------------------
        [+] Running 1/1
         ⠿ Container nginx-reverse-proxy  Removed

        # 정상 종료 확인하기
        docker compose ps -a
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        WARN[0000] The "CONF" variable is not set. Defaulting to a blank string. 
        NAME                COMMAND             SERVICE             STATUS              PORTS
        ```

## 고려해야 할 사항
- ngx_http_upstream_module의 max_fails와 fail_timeout 지시자의 동작
    1. fail_timeout 시간 내 해당 upstream에 대해 max_fails 회수 만큼 연결이 실패한다면, 해당 upstream에 대해 fail_timeout 시간 만큼 unavailable 된 것으로 간주하며 로드 밸런싱하지 않는다.
    2. fail_timeout 시간이 지난 후 해당 upstream에 대해 다시 로드 밸런싱을 수행하며 이 떄 바로 실패한다면 max_fails 회수와 상관없이 바로 1번의 실패에 대해 다시 fail_timeout 시간 만큼 unavailable로 간주 및 로드 밸런싱하지 않는다(해당 내용 루프). 반대로 fail_timeout 시간이 지난 후 해당 upstream에 대해 다시 로드 밸런싱을 수행할 때 정상 통신이 되고, 이 후 실패 상황에 대해서는 처음(1.)로직 부터 다시 실행한다.

## 개선 사항
- official nginx image에 사용자/그룹 추가하기
    - 임시 방편으로 conf/nginx.conf 내 user 지시자를 사용해 nginx worker process의 사용자/그룹을 `wasd:operators`로 하드 코딩했다. 그리고 nginx official image 내 사용자/그룹 생성을 위해 init_script/init.sh.template 파일을 작성했지만 이는 run.sh를 실행하는 사용자/그룹을 이용한다. 그렇기 때문에 `wasd:operators`가 아닌 계정을 통해 /run.sh을 실행시키면 nginx container 실행 시 오류가 발생한다. 뿐만 아니라 이는 worker 프로세스를 `wasd:operators`로 실행시키는 것이지 main 프로세스는 여전히 `root:root`다.


## 참고
- [nginx official document](https://docs.nginx.com)