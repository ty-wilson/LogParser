//
//  LogTraceView.swift
//  Log Parser
//
//  Created by Tyler Wilson on 2/5/23.
//  Copyright © 2023 Tyler Wilson. All rights reserved.
//

import SwiftUI

@available(macOS 11.0, *)
struct LogTraceView: View {
    @EnvironmentObject var filter: Filter
    @EnvironmentObject var dataHelper: DataHelper
    @ObservedObject var log: Log
    @Binding var selectedLineNum: Int
    @State var hasCopied = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if #available(macOS 12.0, *) {
                        Text("Trace at line \(selectedLineNum):").bold().foregroundColor(Color.secondary).textSelection(.enabled)
                    } else {
                        Text("Trace at line \(selectedLineNum):").bold().foregroundColor(Color.secondary)
                    }
                    
                    Button("Open log at this line", action: {
                        let appleScript1 = "tell app \"Terminal\" to do script \"nano +\(self.selectedLineNum + 1) '\(self.dataHelper.getFilePath())'\""
                        let appleScript2 = "tell app \"Terminal\" to set bounds of front window to {0, 0, 1200, 9999} & activate"
                        var error: NSDictionary?

                        func executeScript(script: String){
                            if let scriptObject = NSAppleScript(source: script) {
                                if let output = scriptObject.executeAndReturnError(&error).stringValue {
                                    print(output)
                                } else if (error != nil) {
                                    print("error: ", error!)
                                }
                            }
                        }

                        executeScript(script: appleScript1)
                        executeScript(script: appleScript2)
                        //openFullLogWindow(dataHelper: dataHelper)
                    })
                    .onHover(perform: {val in
                        if(val){
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    
                    Button("Copy to clipboard", action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                        var stringToCopy = DataHelper.dateToLongTextFormatter.string(from: self.log.dateAtLine[self.selectedLineNum]!!) + " "
                        stringToCopy += "[" + self.log.title.rawValue + "] "
                        stringToCopy += "[" + self.log.threadAtLine[self.selectedLineNum]! + "] "
                        stringToCopy += "[" + self.log.process + "] - "
                        stringToCopy += self.log.traceAtLine[self.selectedLineNum]!
                        pasteboard.setString(stringToCopy, forType: NSPasteboard.PasteboardType.string)
                        self.hasCopied = true
                    })
                    .onHover(perform: {val in
                        if(val){
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    })
                    
                    Spacer()
                }
                .frame(minWidth: 350)
                
                if #available(macOS 12.0, *) {
                    StyledText(verbatim: log.traceAtLine[selectedLineNum]!)
                        .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)//magic to make the textbox fit
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    StyledText(verbatim: log.traceAtLine[selectedLineNum]!)
                        .style(.highlight(), ranges: { filter.includeTrace ? (filter.ignoreCase ? $0.lowercased().ranges(of: filter.searchText.lowercased()) : $0.ranges(of: filter.searchText)) : [] })
                        .fixedSize()//magic to make the textbox fit
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            
            Spacer()
        }
    }
}

func openFullLogWindow(dataHelper: DataHelper) {
    // Create the preferences window and set content
    let fullLogWindow = NSWindow(
        contentRect: NSRect(x: 20, y: 20, width: 480, height: 300),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false)
    let fullLogView = FullLogView(fullLogLine: 1, window: fullLogWindow).environmentObject(dataHelper)
    
    fullLogWindow.center()
    fullLogWindow.setFrameAutosaveName("Full Log")
    fullLogWindow.isReleasedWhenClosed = false
    fullLogWindow.contentView = NSHostingView(rootView: fullLogView)
    fullLogWindow.makeKeyAndOrderFront(nil)
}

@available(macOS 11.0, *)
struct LogTraceView_Previews: PreviewProvider {
    static var previews: some View {
        LogTraceView(log: Log(lineNum: [1, 2],
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
                     selectedLineNum: .constant(1))
            .environmentObject(Filter())
            .environmentObject(DataHelper())
    }
}


