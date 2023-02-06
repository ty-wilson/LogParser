//
//  LogDetailsView.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import SwiftUI

struct LogDetailsView: View {
    @ObservedObject var log: Log
    @EnvironmentObject var filter: Filter
    
    @State var selectedLineNum: Int?
    
    var body: some View {
        HStack {
            //Line | Date | Thread selectable list
            VStack(alignment: .leading) {
                List (log.lineNum, selection: $selectedLineNum) { num in
                    HStack {
                        //Add line, date and thread
                        
                        Text("line \(num):")
                            .foregroundColor(.secondary)
                        StyledText(verbatim: "\(FileHandler.dateToLongTextFormatter.string(from: self.log.dateAtLine[num]!!))")
                            .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                            .foregroundColor(Color.uiBlue)

                        StyledText(verbatim: "[\(self.log.threadAtLine[num]!)]")
                            .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                            .foregroundColor(Color.uiPurple)
                    }
                }
            }.padding([.top, .bottom], 10)
            .frame(width: 460)
            
            //Text: Combine text with other text
            if(selectedLineNum != nil) {
                LogTraceView(log: log,
                             selectedLineNum: $selectedLineNum)
                    .padding(.leading, 10)
                    .frame(idealWidth: 900)//more magic
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        
                        Text(verbatim: "")
                        Spacer()
                    }
                    Spacer()
                }
                .frame(idealWidth: 900)
            }
        }
    }
}

struct LogDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        LogDetailsView(log: Log(lineNum: [1, 2],
                                dateAtLine: [1 : Date(), 2 : Date()],
                                title: .ERROR,
                                threadAtLine: [ 1 : "ThreadName" , 2 : "OtherThread"],
                                process: "ProcessName",
                                text: "Text Here",
                                traceAtLine: [ 1 : """
                                                \nThursday, January 26, 2023 at 11:35:16 AM [ERROR] [startStop-1] [onfigurationProfileHelper] - Profile contents could not be retrieved
                                                java.lang.NullPointerException: null
                                                 at com.jamfsoftware.jss.objects.configurationprofile.ConfigurationProfileHelper.getProfileContents(ConfigurationProfileHelper.java:69) ~[classes/:?]
                                                 at com.jamfsoftware.jss.objects.configurationprofile.ConfigurationProfile.fillContents(ConfigurationProfile.java:278) ~[classes/:?]
                                                 at com.jamfsoftware.jss.objects.configurationprofile.ConfigurationProfile.getPayloads(ConfigurationProfile.java:190) ~[classes/:?]
                                                 at com.jamfsoftware.jss.objects.configurationprofile.predefined.factory.SettingsMdmDeployFactory.readProfile(SettingsMdmDeployFactory.java:71) ~[classes/:?]
                                                 at com.jamfsoftware.jss.objects.configurationprofile.predefined.factory.SettingsMdmDeployFactory.<init>(SettingsMdmDeployFactory.java:34) ~[classes/:?]
                                                 at jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance0(Native Method) ~[?:?]
                                                 at jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance(NativeConstructorAccessorImpl.java:62) ~[?:?]
                                                 at jdk.internal.reflect.DelegatingConstructorAccessorImpl.newInstance(DelegatingConstructorAccessorImpl.java:45) ~[?:?]
                                                 at java.lang.reflect.Constructor.newInstanceWithCaller(Constructor.java:500) ~[?:?]
                                                 at java.lang.reflect.Constructor.newInstance(Constructor.java:481) ~[?:?]
                                                 at org.springframework.beans.BeanUtils.instantiateClass(BeanUtils.java:211) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:87) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.instantiateBean(AbstractAutowireCapableBeanFactory.java:1326) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1232) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:582) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:542) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.lambda$doGetBean$0(AbstractBeanFactory.java:335) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:234) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:333) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:208) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.config.DependencyDescriptor.resolveCandidate(DependencyDescriptor.java:276) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.addCandidateEntry(DefaultListableBeanFactory.java:1609) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.findAutowireCandidates(DefaultListableBeanFactory.java:1573) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.resolveMultipleBeans(DefaultListableBeanFactory.java:1462) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.doResolveDependency(DefaultListableBeanFactory.java:1349) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.resolveDependency(DefaultListableBeanFactory.java:1311) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.ConstructorResolver.resolveAutowiredArgument(ConstructorResolver.java:887) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.ConstructorResolver.createArgumentArray(ConstructorResolver.java:791) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.ConstructorResolver.autowireConstructor(ConstructorResolver.java:229) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.autowireConstructor(AbstractAutowireCapableBeanFactory.java:1372) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1222) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:582) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:542) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.lambda$doGetBean$0(AbstractBeanFactory.java:335) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:234) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:333) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:208) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:955) ~[spring-beans-5.3.23.jar:5.3.23]
                                                 at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:918) ~[spring-context-5.3.23.jar:5.3.23]
                                                 at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:583) ~[spring-context-5.3.23.jar:5.3.23]
                                                 at org.springframework.web.context.ContextLoader.configureAndRefreshWebApplicationContext(ContextLoader.java:401) ~[spring-web-5.3.23.jar:5.3.23]
                                                 at com.jamfsoftware.jss.server.JssContextLoaderListener.configureAndRefreshWebApplicationContext(JssContextLoaderListener.java:287) ~[classes/:?]
                                                 at org.springframework.web.context.ContextLoader.initWebApplicationContext(ContextLoader.java:292) ~[spring-web-5.3.23.jar:5.3.23]
                                                 at org.springframework.web.context.ContextLoaderListener.contextInitialized(ContextLoaderListener.java:103) ~[spring-web-5.3.23.jar:5.3.23]
                                                 at com.jamfsoftware.jss.server.JssContextLoaderListener.contextInitialized(JssContextLoaderListener.java:119) ~[classes/:?]
                                                 at org.apache.catalina.core.StandardContext.listenerStart(StandardContext.java:4763) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.core.StandardContext.startInternal(StandardContext.java:5232) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:183) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.core.ContainerBase.addChildInternal(ContainerBase.java:753) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.core.ContainerBase.addChild(ContainerBase.java:727) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.core.StandardHost.addChild(StandardHost.java:695) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.startup.HostConfig.deployDirectory(HostConfig.java:1177) ~[catalina.jar:8.5.82]
                                                 at org.apache.catalina.startup.HostConfig$DeployDirectory.run(HostConfig.java:1925) ~[catalina.jar:8.5.82]
                                                 at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:515) ~[?:?]
                                                 at java.util.concurrent.FutureTask.run(FutureTask.java:264) ~[?:?]
                                                 at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1128) ~[?:?]
                                                 at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:628) ~[?:?]
                                                 at java.lang.Thread.run(Thread.java:835) ~[?:?]
                                                """, 2 : "\nAnother trace here"],
                                showDetails: true),
                       selectedLineNum: 1)
        .environmentObject(Filter())
    }
}
