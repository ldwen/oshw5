#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <fcntl.h> 
#include <errno.h>
#include <pwd.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/stat.h> 

#define MAX 100
#define LEN 100

//shell指令单个管道结构体
struct cmd_list{  
    int argc;  //单个管道参数个数
    char *argv[MAX];
};

struct cmd_list *cmdv[MAX];  //shell指令
int num;//shell管道个数

//执行外部命令
void execute(char *argv[])
{
        int error;
        error=execvp(argv[0],argv);
        if (error==-1)  printf("failed!\n");
        exit(1);
}

//切分单个管道
void split_cmd(char *line)
{
     struct cmd_list * cmd = (struct cmd_list *)malloc(sizeof(struct cmd_list));
     cmdv[num++] = cmd;
     cmd->argc = 0;
     char *save;
     char *arg = strtok_r(line, " \t", &save);//切分空格
     while (arg)
     {
        cmd->argv[cmd->argc] = arg;
        arg = strtok_r(NULL, " \t", &save);
        cmd->argc++;
     }
     cmd->argv[cmd->argc] = NULL;
}

//切分管道
void split_pipe(char *line)
{
    char *save;
    char * cmd = strtok_r(line, "|", &save);
    while (cmd) {
        split_cmd(cmd);
        cmd = strtok_r(NULL, "|", &save);
    }
}

//执行管道命令
void do_pipe(int index)
{
    if (index == num - 1)
        execute(cmdv[index]->argv);
    int fd[2];
    pipe(fd);//创建管道，0读，1写
    if (fork() == 0)
    {
        dup2(fd[1], 1);
        close(fd[0]);
        close(fd[1]);
        execute(cmdv[index]->argv);
    }
    dup2(fd[0], 0);
    close(fd[0]);
    close(fd[1]);
    do_pipe(index + 1);
}

//执行内部指令
int inner(char *line)
{
    char *save,*tmp[MAX];
    char t[LEN],p[LEN];
    strcpy(t,line);
    char *arg = strtok_r(line, " \t", &save);//切分空格
    int i=0;
    while (arg) {
        tmp[i] = arg;
        i++;//记录命令个数
        arg = strtok_r(NULL, " \t", &save);
     }
    tmp[i] = NULL;
    if (strcmp(tmp[0],"exit")==0)//exit
    {
        exit(0);
        return 1;
    }
    else
    if (strcmp(tmp[0],"pwd")==0)//pwd
    {
        char buf[LEN];
        getcwd(buf,sizeof(buf));//得到当前路径
        printf("Current dir is:%s\n",buf);
        return 1;
    }
    else
    if (strcmp(tmp[0],"cd")==0)//cd
    {
        char buf[LEN];
        if (chdir(tmp[1])>=0)
        {
            getcwd(buf,sizeof(buf));
        }
        else
        {
            printf("Error path!\n");
        }
        return 1;
    }
    else return 0;
}

int main()
{
    int i,pid;
    char buf[LEN],p[LEN];
    struct passwd *pwd;
    while (1)
    {   char hostname[100];
        char pathname[100];
        int length;
        pwd = getpwuid(getuid());//获得用户名
        getcwd(pathname,100);//获得路径名
        if(gethostname(hostname,100)==0)//获得主机名
            printf("%s@%s:",pwd->pw_name,hostname);
        else
            printf("%s@unknown:",pwd->pw_name);

        if(strlen(pathname) < strlen(pwd->pw_dir) ||   strncmp(pathname,pwd->pw_dir,strlen(pwd->pw_dir))!=0)
            printf("%s",pathname);
        else
            printf("~%s",pathname+strlen(pwd->pw_dir));

        if(geteuid()==0)
            printf("#");
        else
            printf("$");

        fgets(buf,LEN,stdin);//读入shell指令
        if (buf[0]=='\n') continue;
        buf[strlen(buf)-1]='\0';
        strcpy(p,buf);
        int inner_flag;
        inner_flag=inner(buf);//执行内置指令
        if (inner_flag==0)
        {
            pid=fork();//建立新进程
            if (pid==0)
            {
                split_pipe(p);//管道切割
                do_pipe(0);//执行管道
                exit(0);
            }
            waitpid(pid,NULL,0);
        }
    }
    return 0;
}
