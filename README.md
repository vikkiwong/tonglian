微信通联
========
功能
--------
*  借助微信平台方便的管理群体联系方式
*  通过邮箱验证绑定微信号，由自己随时维护更新
*  便利的查询功能，支持汉字、拼音、拼音首字母等多种查询方式

运行环境
--------
*  ruby 1.9.2
*  rails 3.2.8
*  mysql2

Gem包
--------
*  分页插件  will_paginate, bootstrap-will_paginate
*  汉字转拼音插件 ruby-pinyin

前端样式
--------
*  bootstrap

使用说明
--------
1. checkout 项目代码

        git clone https://github.com/vikkiwong/tonglian.git

2. 安装gem包
 
        bundle install
        
3. 建立数据库

        rake db:create
        rake db:migrate
        rake db:seed
        
4. 启动项目

        rails server

5. 访问并使用管理员账号登陆
      
    邮箱   **admin@email.com**
    
    密码   __admin__

6. 导入用户
   
   格式: email（必填）, 姓名（选填）   
   多个用户分行

7. 申请微信账号并关联应用

   普通用户关注微信账号后，验证邮箱（该邮箱必须已经由管理员导入数据库）即可使用微信通联，管理自己、查询他人的联系方式！


欢迎任何帮助
--------
###### 如果你喜欢这个项目，请通过(不限)以下方式帮助它!
*  各种使用
*  各种宣传
*  各种报告bug, 提供建议 (github issue tracker)
*  各种修bug, 实现feature (github pull request)

