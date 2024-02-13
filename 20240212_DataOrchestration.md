# Data Orchestration
1. Data is written into Azure Blob Storage on a daily cadence in a csv file. Describe a process how you would create a new table in a Snowflake database off of the Azure Blob Storage source. We want the Snowflake table to be updated on a weekly cadence. Provide a written explanation.

We can use Snowflake's Snowpipe to automatically ingest the csv file whenever the file is written into Azure Blob Storage using its auto ingest capabilities. The way this works is that snowflake listens to specific events in the Azure Blob Storage in order to trigger the Snowpipe to load the file. Only Microsoft.Storage.BlobCreated events triggers Snowpipe to load files. The APIs supported within these events are:
* CopyBlob
* PutBlob
* PutBlockList
* FlushWithClose
* SftpCommit

Basic process flow are as follows:
1. Data files are loaded in a stage (azure blob storage)
2. Blob storage event message informs Snowpipe via Event Grid that files are ready to load. Snowpipe brings file into a queue.
3. Snowflake-provided virtual warehouse loads data from queued files into the target table based on parameters defined in pipe.

I will assume that the Snowflake environment has credentials already set up in order to access the Azure Blob Storage. If not then we would need to create a Cloud Storage Integration object within Snowflake. This object stores a generated service principal for an Azure cloud storage instance as well as set allowed or blocked storage containers. This lets us avoid having to supply credentials when creating stages or loading data.

We will also need to configure the Azure Event Grid subscription in order to detect when new files are loaded onto the Azure Blob Storage. An Event Grid topic provides an endpoint where the source sends events. A GPv2 storage account must be created in order to host the storage queue. This kind of account is the only type of account that supports event messages to a storage queue. You can also choose to host the data files on the same GPv2 account, but you can also choose to host the data files in a Blob Storage Account. We will use the ***storageid*** from the Storage Account object and the ***queueid*** from the Event Grid object in order to create an Event Grid Subscription. We will then create a snowflake object called notification integration which provides an interface between Snowflake and third-party cloud message queueing services like Azure Event Grid. Its important to note that a single notification integration supports a single Azure Storage queue. Referencing the same storage queue in multiple notification integrations could result in missing data. 

We will need to create an external stage that references our Azure container (if one is not already existing) using the Snowflake command **CREATE STAGE**. We then will need to create a pipe using the **CREATE PIPE** command with the *auto_ingest* property enabled and specifying the *integration* property with the notification integration name (in all caps) that was created earlier. 
```
CREATE PIPE snowpipe_db.public.dailyCSVPipe
  AUTO_INGEST = TRUE
  INTEGRATION = '<NOTIFICATION_INTEGRATION_NAME>'
  AS
  COPY INTO snowpipe_db.public.CSVTable
  FROM @snowpipe_db.public.externalStage
  file_format = {type = 'CSV'};
```
In order to load historical files, we must execute an **ALTER PIPE ... REFRESH** statement. 

Pipe objects do not support the **PURGE** copy option. Therefore Snowpipe cannot delete staged files automatically when the data is successfully loaded into tables. To remove staged files that ar eno longer needed, we will need to periodically execute the **REMOVE** command. 


 
2. Let's say the above data is in our Snowflake database and the end users are asking for delivery of insights. How could we make aggregated data available for an external user to consume? Give consideration to whether the client wants the data pushed to them versus available for them to pull when needed. Assume the data cannot be passed via an emailed csv.

There are a few different ways we can make the aggregated data available for an external user or group to consume. If the client is internal within the organization we can create a Snowflake db for which their group would have read access to. They would then be able to query the aggregated data as they please. Alternatively if the client has a need to consume the aggregated data into an application and are able to call APIs; they can call Snowflake's sql statement execution API. which should return a ResultSet object upon successful statement execution. There are also various drivers that downstream applications are able to use depending on their tech stack that can also query data from snowflake db and tables. The drivers currently available are:
* Go
* JDBC
* .NET
* Node.js
* ODBC
* PHP
* Python

For situations where the client wants the data pushed to them, we can keep a meta-data table of the different tables that the client wishes to consume. Ideally the tables will have timestamp data so we can keep track of when the last data unload was. Otherwise we will have to do full unloads. By keeping track of the meta data, we can unload deltas of the data into external stages. From the external stage we can then use ADF (or any other data orchestration tool) to move the data into its desired location.










