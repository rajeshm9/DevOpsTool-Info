from jira import JIRA
from datetime import datetime
import time
import pandas as pd
import csv
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.pyplot as plt



#

def time_diff(initTime, endTime):
    
    fmt='%Y-%m-%dT%H:%M:%S.000%z'
    initTimeObj =  datetime.strptime(initTime, fmt )
    endTimeObj =  datetime.strptime(endTime, fmt)
    duration = endTimeObj - initTimeObj
        
    #return duration
    timeInMin = int(duration.total_seconds()/60) #in min
    return timeInMin




    
def status_time(initTime, changelog):
    
    toDoTime=initTime
    changeLogHistory=[]
    
    ttfr = True
    ttfrTime=-1
    doneTime=-1
    for history in changelog.histories:
        for item in history.items:
            if item.field == 'status':
                endTime = history.created
                td = str(time_diff(initTime, endTime))
                if item.fromString == 'To Do' and ttfr == True:
                    ttfrTime =td
                    ttfr = False
                #print ('Date:' + endTime + ' From:' + item.fromString + ' To:' + item.toString + ' TD: ' + td)
                changeLogHistory.extend([item.fromString,td])
                initTime = endTime
                if item.toString == 'Done':
                    doneTime =time_diff(toDoTime,endTime)
                    
    l = [ttfrTime,doneTime]
    l.extend(changeLogHistory)
    print(l)
    return l;
###### configuration ###########
url="xxxxx"
PROJ_NAME='xxxx'
options = {"server": url}
USER_NAME='xxx'
USER_PASS='xxxx'

fieldList='summary,created,status,customfield_14545,customfield_29590,assignee,reporter,issuetype,priority,components'

query='project='+PROJ_NAME+' AND created >= 2020-04-01 AND created < 2020-05-01 ORDER BY created ASC'
maxResults = 500
fileName="CSV_FILE" 


##########################

jira_conn = JIRA(options,basic_auth=(USER_NAME, USER_PASS))
issues_in_proj = jira_conn.search_issues(query, maxResults=maxResults, expand='changelog', fields=fieldList)

print(issues_in_proj.total)

with open(fileName+'.csv', 'w', newline='') as csvfile:
    fieldnames = ['Issue_No','Summary','Component','Created_Date','IssueType','Priority','Status','Team','Market','Assignee','Reporter','FTTR','ClosureTime','Status_0','Time_0','Status_1','Time_1','Status_2','Time_2','Status_3','Time_3','Status_4','Time_4']
    #writer = csv.DictWriter(csvfile, fieldnames=fieldname
    writer = csv.writer(csvfile, delimiter=',',quoting=csv.QUOTE_MINIMAL)
    writer.writerow(fieldnames)
    
    for issue in issues_in_proj:
        #for attribute, value in issue.__dict__.items():
        #    print(attribute, '=', value)
        #print('{}: {}'.format(issue.key, issue.fields.summary))
        f=issue.fields
        changelog = issue.changelog
        try:
            issueDesc = [issue.key, f.summary.replace("|"," "), f.components[0].name, f.created, f.issuetype.name, f.priority.name, f.status.name, f.customfield_14545.value, f.customfield_29590.value,f.assignee.emailAddress,f.reporter.emailAddress]
            issueDesc.extend(status_time(f.created, changelog))
            print(issueDesc)
            writer.writerow(issueDesc)
        except:
            pass
df = pd.read_csv(fileName+'.csv')

## Get the Status Count 
#d = df.Status.value_counts()
width=20
height=25
fontsize=10

d1=df.Status.value_counts() #Status count
d2=df.Market.value_counts() #Market Count
d3=df.Reporter.value_counts() #reporter
d4=df.Team.value_counts() #Team Count
d5=df.IssueType.value_counts() #Issue Type
d6=df.Component.value_counts() #Component 
d7=pd.to_datetime(df.Created_Date.str.slice(0,10)).value_counts() # df.Created_Date.str.slice(0,10).value_counts() # Daily Ticket Count
fig, axes = plt.subplots(4, 2)
plt.subplots_adjust(hspace=0.5)

'''
out=pd.cut(df.ClosureTime,bins=[-1, 0, 60, 60*5, 60*24, 60*24*5, 60*24*10, 60*24*100, 60*24*1000],include_lowest=True)
close_sla=out.value_counts().reindex(out.cat.categories)
'''
out=pd.cut(df.FTTR,bins=[-1, 0, 60, 60*5, 60*24, 60*24*5, 60*24*10, 60*24*30, 60*24*1000],include_lowest=True)
sla=out.value_counts().reindex(out.cat.categories)

out=pd.cut(df.ClosureTime, bins=[-1, 0, 60, 60*5, 60*24, 60*24*5, 60*24*10, 60*24*30, 60*24*1000],include_lowest=True)
close_sla=out.value_counts().reindex(out.cat.categories)

d7.plot(kind='line', ax=axes[0,0], title='Daily Ticket',fontsize=fontsize, figsize=(width, height))
d1.plot(kind='bar', ax=axes[0,1], title='Ticket Status',fontsize=fontsize, figsize=(width, height))

ax = sla.plot(kind='bar',  ax=axes[1,0], title='First Response Time', fontsize=fontsize, figsize=(width, height))

ax.set_xticklabels(['No Response', '1 Hour','5 Hour','1 Day','5 Days','10 Day','30 Day','1000 Days'])

ax = close_sla.plot(kind='bar', ax=axes[1,1], title='Closure Time',fontsize=fontsize, figsize=(width, height))
ax.set_xticklabels(['Not Done','1 Hour','5 Hour','1 Day','5 Days','10 Days','30 Days','1000 Days'])

#d3.plot(kind='pie',  ax=axes[1,0], title='Reporter Wise Count',autopct='%.2f', figsize=(width, height))

d4.plot(kind='pie',  ax=axes[2,0], title='Team Wise Count',fontsize=fontsize, autopct='%.2f', figsize=(width, height))
d5.plot(kind='pie',  ax=axes[2,1], title='IssueType Wise Count', fontsize=fontsize, autopct='%.2f', figsize=(width, height))
d6.plot(kind='pie',  ax=axes[3,0], title='Component Wise Count', fontsize=fontsize, autopct='%.2f', figsize=(width, height))
d2.plot(kind='pie',  ax=axes[3,1], title='Market Wise Count', fontsize=fontsize, autopct='%.2f', figsize=(width, height))


plt.savefig(fileName+'.pdf')
plt.close('all')



    
