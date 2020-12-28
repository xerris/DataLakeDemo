import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
#from awsglue.transforms import Relationalize
args = getResolvedOptions(sys.argv, ['glue_source_database','glue_source_table','glue_temp_storage','glue_relationalize_output_s3_path'])
# Begin variables to customize with your information
glue_source_database = args['glue_source_database'] #"testdb"
glue_source_table =  args['glue_source_table'] # "lakestack_mylakelanding6df26456_agqxvt1ngc70"
glue_temp_storage =  args['glue_temp_storage'] #"s3://testlakebucket"
glue_relationalize_output_s3_path =  args['glue_relationalize_output_s3_path'] #"s3://jasonoutputglue"
dfc_root_table_name = "root" #default value is "roottable"
# End variables to customize with your information

glueContext = GlueContext(SparkContext.getOrCreate())
datasource0 = glueContext.create_dynamic_frame.from_catalog(database = glue_source_database, table_name = glue_source_table, transformation_ctx = "datasource0")
dfc = Relationalize.apply(frame = datasource0, staging_path = glue_temp_storage, name = dfc_root_table_name, transformation_ctx = "dfc")
blogdata = dfc.select(dfc_root_table_name)
blogdataoutput = glueContext.write_dynamic_frame.from_options(frame = blogdata, connection_type = "s3", connection_options = {"path": glue_relationalize_output_s3_path}, format = "parquet", transformation_ctx = "blogdataoutput")