# Data Modeling Explanation
There are 3 major data modeling design patterns for data warehousing, they are Inmon, Kimball, and Data Vault. 
They each have their advantages and disadvantages.
For example, the Inmon data model is very useful for having a single source of truth for reporting purposes, but require extensive ETL resources to build and maintain their pipelines.
This creates a centralized enterprise data warehouse. 

The Kimball data model is very handy if you are prioritizing usage with business users and you want to prioritize the data for business-driven focus, but you create data redundancy 
and there is a significant effort to maintain consistency across the data marts within the data warehouse.
This model uses denormalized data structures like star and snowflake schemas which makes it easier for business users to query the data.

The Data Vault model is a newer model that attempts to combine elements of both the previously mentioned data models.
It uses a 'hub and spoke' architecture that separates business keys (hubs), relationships (links between the hubs), and attributes (considered satellites connected to hubs).

The model in '20240212_TakeHomeDataModel.pdf' is built out in the format of a Fact - Dimensional Kimball Data model in mind. 
I believe I would need more business context and technical requirements in order to better discuss a data modeling strategy that aligns with our goals. 
Some questions I would ask for the data model:
  Whats the end goal for this data?
    Is it for reporting or analytics?
    Or is it meant for storage?
    Or is it meant to be consumed by ML and DS teams?
    The answer would help us discuss timeline and technical limitations with the resources at our disposal.
  What is the source system(s) for the data?
    Do we need to be mindful of compute load on the source system?
    Will we be pulling the data or receiving the data?
    What does the SLA between us and the source system look like?
    In a worst case scenario, what DR protocols need to be put in place (both on source and DE team side)

With the given sample data, I think a Data Vault data model could potentially be the most effective because of its "insert-optimized" mindset. 
Since the data given is very likely to be streaming data (EVENTHUBID and LOGGED Timestamp is a big clue to this). An insert-optimized data model can prove to be advantageous when handling multiple and varied streaming sources.
However, I don't have much experience in building out Data Vault Data Models. In my current environment we have a Kimball style Data Model strategy. This is because our current reporting structure is very focused on providing our business colleagues with the tools to build dashboards necesarry for their operational function.

Some additional data that would be helpful are:
Additional company information, data information, and alarm information and how they are transactionally-related. As well as the relationship between P1-10 and the rest of the data.
Some assumptions I made are:
  A one to many relationship between streamed data and company
  Alarm, Comapany, and Device are dimensions of the data.
  The data set is a streamed data set.
  EVENTHUBID, ALARMS, COMPANIES, DEVICEID, and LOGGED are NON Nullable data fields.
