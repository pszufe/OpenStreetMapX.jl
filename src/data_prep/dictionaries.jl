###################################
### Datasets dictionaries
###################################



###################################
### Businesses data dictionary

desc_df_businesses = Dict(
    :LATITUDE  => "Latitude",
    :LONGITUDE => "Longitude",
    :NAME   => "Business name",
    :IEMP_DESC => "Number of employees",
    :ISAL_DESC => "Volume of annual sales",
    :ICLS_DESC => "Industry"
)



###################################
### Demographics data dictionary

desc_df_demographics = Dict(
    :DA_ID     => "Dissemination Area id",
    :ECYBASHHD  => "Total Households",
    :ECYBASHPOP => "Total Household Population",
    :ECYBAS15HP => "Total Household Population 15 Years Or Over",
    :ECYBAS18HP => "Total Household Population 18 Years Or Over",
    :ECYBASKID  => "Total Children Living In Households (Children At Home)",
    :ECYBASLF   => "In The Labour Force",
    :ECYHTA_0_4 => "Household Population by Age - 0 To 4",
    :ECYHTA_5_9 => "Household Population by Age - 5 To 9",
    :ECYHTA1014 => "Household Population by Age - 10 To 14",
    :ECYHTA1519 => "Household Population by Age - 15 To 19",
    :ECYHTA2024 => "Household Population by Age - 20 To 24",
    :ECYHTA2529 => "Household Population by Age - 25 To 29",
    :ECYHTA3034 => "Household Population by Age - 30 To 34",
    :ECYHTA3539 => "Household Population by Age - 35 To 39",
    :ECYHTA4044 => "Household Population by Age - 40 To 44",
    :ECYHTA4549 => "Household Population by Age - 45 To 49",
    :ECYHTA5054 => "Household Population by Age - 50 To 54",
    :ECYHTA5559 => "Household Population by Age - 55 To 59",
    :ECYHTA6064 => "Household Population by Age - 60 To 64",
    :ECYHTA6569 => "Household Population by Age - 65 To 69",
    :ECYHTA7074 => "Household Population by Age - 70 To 74",
    :ECYHTA7579 => "Household Population by Age - 75 To 79",
    :ECYHTA8084 => "Household Population by Age - 80 To 84",
    :ECYHTA85P  => "Household Population by Age - 85 Or Older",
    :ECYHTAAVG  => "Average Age Of Total Household Population",
    :ECYHTAMED  => "Median Age Of Total Household Population",
    :ECYHMAHPOP => "Household Population Male",
    :ECYHMA_0_4 => "Male Household Population by Age - 0 To 4",
    :ECYHMA_5_9 => "Male Household Population by Age - 5 To 9",
    :ECYHMA1014 => "Male Household Population by Age - 10 To 14",
    :ECYHMA1519 => "Male Household Population by Age - 15 To 19",
    :ECYHMA2024 => "Male Household Population by Age - 20 To 24",
    :ECYHMA2529 => "Male Household Population by Age - 25 To 29",
    :ECYHMA3034 => "Male Household Population by Age - 30 To 34",
    :ECYHMA3539 => "Male Household Population by Age - 35 To 39",
    :ECYHMA4044 => "Male Household Population by Age - 40 To 44",
    :ECYHMA4549 => "Male Household Population by Age - 45 To 49",
    :ECYHMA5054 => "Male Household Population by Age - 55 To 59",
    :ECYHMA5559 => "Male Household Population by Age - 50 To 54",
    :ECYHMA6064 => "Male Household Population by Age - 60 To 64",
    :ECYHMA6569 => "Male Household Population by Age - 65 To 69",
    :ECYHMA7074 => "Male Household Population by Age - 70 To 74",
    :ECYHMA7579 => "Male Household Population by Age - 75 To 79",
    :ECYHMA8084 => "Male Household Population by Age - 80 To 84",
    :ECYHMA85P  => "Male Household Population by Age - 85 Or Older",
    :ECYHMAAVG  => "Average Age Of Household Population Male",
    :ECYHMAMED  => "Median Age Of Household Population Male",
    :ECYHFAHPOP => "Household Population Female",
    :ECYHFA_0_4 => "Female Household Population by Age - 0 To 4",
    :ECYHFA_5_9 => "Female Household Population by Age - 5 To 9",
    :ECYHFA1014 => "Female Household Population by Age - 10 To 14",
    :ECYHFA1519 => "Female Household Population by Age - 15 To 19",
    :ECYHFA2024 => "Female Household Population by Age - 20 To 24",
    :ECYHFA2529 => "Female Household Population by Age - 25 To 29",
    :ECYHFA3034 => "Female Household Population by Age - 30 To 34",
    :ECYHFA3539 => "Female Household Population by Age - 35 To 39",
    :ECYHFA4044 => "Female Household Population by Age - 40 To 44",
    :ECYHFA4549 => "Female Household Population by Age - 45 To 49",
    :ECYHFA5054 => "Female Household Population by Age - 50 To 54",
    :ECYHFA5559 => "Female Household Population by Age - 55 To 59",
    :ECYHFA6064 => "Female Household Population by Age - 60 To 64",
    :ECYHFA6569 => "Female Household Population by Age - 65 To 69",
    :ECYHFA7074 => "Female Household Population by Age - 70 To 74",
    :ECYHFA7579 => "Female Household Population by Age - 75 To 79",
    :ECYHFA8084 => "Female Household Population by Age - 80 To 84",
    :ECYHFA85P  => "Female Household Population by Age - 85 Or Older",
    :ECYHFAAVG  => "Average Age Of Household Population Female",
    :ECYHFAMED  => "Median Age Of Household Population Female",
    :ECYHSZ1PER => "Total Households For Household Size - 1 Person",
    :ECYHSZ2PER => "Total Households For Household Size - 2 Persons",
    :ECYHSZ3PER => "Total Households For Household Size - 3 Persons",
    :ECYHSZ4PER => "Total Households For Household Size - 4 Persons",
    :ECYHSZ5PER => "Total Households For Household Size - 5 Persons",
    :ECYMARMCL  => "Total Population 15 Years Or Over - Married Or Living With A Common-Law Partner",
    :ECYMARNMCL => "Total Population 15 Years Or Over - Not Married And Not Living With A Common-Law Partner",
    :ECYHFSCNC  => "Total Households with Couple Without Children At Home", 
    :ECYHFSCWC  => "Total Households with Couple With Children At Home", 
    :ECYHFSC1C  => "Total Households with Couple 1 Child", 
    :ECYHFSC2C  => "Total Households with Couple 2 Children", 
    :ECYHFSC3C  => "Total Households with Couple 3 Or More Children", 
    :ECYHFSLP   => "Total Households with Lone-Parent Total Lone-Parent Family Households", 
    :ECYHFSLP1C => "Total Households with Lone-Parent 1 Child", 
    :ECYHFSLP2C => "Total Households with Lone-Parent 2 Children", 
    :ECYHFSLP3C => "Total Households with Lone-Parent 3 Or More Children", 
    :ECYCHA_0_4 => "Total Children At Home by Age - 0 To 4",
    :ECYCHA_5_9 => "Total Children At Home by Age - 5 To 9",
    :ECYCHA1014 => "Total Children At Home by Age - 10 To 14",
    :ECYCHA1519 => "Total Children At Home by Age - 15 To 19",
    :ECYCHA2024 => "Total Children At Home by Age - 20 To 24",
    :ECYCHA25P  => "Total Children At Home by Age - 25 Or More",
    :ECYHRI_010 => "Total Households by Income - ",
    :ECYHRI1020 => "Total Households by Income - 10,000 To 19,999 (Constant Year 2005 \$)",
    :ECYHRI2030 => "Total Households by Income - 20,000 To 29,999 (Constant Year 2005 \$)",
    :ECYHRI3040 => "Total Households by Income - 30,000 To 39,999 (Constant Year 2005 \$)",
    :ECYHRI4050 => "Total Households by Income - 40,000 To 49,999 (Constant Year 2005 \$)",
    :ECYHRI5060 => "Total Households by Income - 50,000 To 59,999 (Constant Year 2005 \$)",
    :ECYHRI6070 => "Total Households by Income - 60,000 To 69,999 (Constant Year 2005 \$)",
    :ECYHRI7080 => "Total Households by Income - 70,000 To 79,999 (Constant Year 2005 \$)",
    :ECYHRI8090 => "Total Households by Income - 80,000 To 89,999 (Constant Year 2005 \$)",
    :ECYHRIX100 => "Total Households by Income - 90,000 To 99,999 (Constant Year 2005 \$)",
    :ECYHRIX125 => "Total Households by Income - 100,000 To 124,999 (Constant Year 2005 \$)",
    :ECYHRIX150 => "Total Households by Income - 125,000 To 149,999 (Constant Year 2005 \$)",
    :ECYHRIX175 => "Total Households by Income - 150,000 To 174,999 (Constant Year 2005 \$)",
    :ECYHRIX200 => "Total Households by Income - 175,000 To 199,999 (Constant Year 2005 \$)",
    :ECYHRIX250 => "Total Households by Income - 200,000 To 249,999 (Constant Year 2005 \$)",
    :ECYHRI250P => "Total Households by Income - 250,000 Or Over (Constant Year 2005 \$)",
    :ECYHRIAVG  => "Average Household Income (Constant Year 2005 \$)",
    :ECYHRIMED  => "Median Household Income (Constant Year 2005 \$)",
    :ECYOCCNA   => "HH Pop 15 years or over in Labour Force - Occupation Not Applicable",
    :ECYOCCMGMT => "HH Pop 15 years or over in Labour Force - Management",
    :ECYOCCBFAD => "HH Pop 15 years or over in Labour Force - Business Finance Administration",
    :ECYOCCNSCI => "HH Pop 15 years or over in Labour Force - Occupations In Sciences",
    :ECYOCCHLTH => "HH Pop 15 years or over in Labour Force - Occupations In Health",
    :ECYOCCSSER => "HH Pop 15 years or over in Labour Force - Occupations In Social Science, Education, Government, Religion",
    :ECYOCCARTS => "HH Pop 15 years or over in Labour Force - Occupations In Art, Culture, Recreation, Sport",
    :ECYOCCSERV => "HH Pop 15 years or over in Labour Force - Occupations In Sales And Service",
    :ECYOCCTRAD => "HH Pop 15 years or over in Labour Force - Occupations In Trades, Transport, Operators",
    :ECYOCCPRIM => "HH Pop 15 years or over in Labour Force - Occupations Unique To Primary Industries",
    :ECYOCCSCND => "HH Pop 15 years or over in Labour Force - Occupations Unique To Manufacture And Utilities",
    :ECYINDINLF => "HH Pop 15 years or over by industry - ",
    :ECYINDNA   => "HH Pop 15 years or over by industry - Industry - Not Applicable",
    :ECYINDAGRI => "HH Pop 15 years or over by industry - 11 Agriculture, Forestry, Fishing And Hunting",
    :ECYINDMINE => "HH Pop 15 years or over by industry - 21 Mining, Quarrying, And Oil And Gas Extraction",
    :ECYINDUTIL => "HH Pop 15 years or over by industry - 22 Utilities",
    :ECYINDCSTR => "HH Pop 15 years or over by industry - 23 Construction",
    :ECYINDMANU => "HH Pop 15 years or over by industry - 31-33 Manufacturing",
    :ECYINDWHOL => "HH Pop 15 years or over by industry - 41 Wholesale Trade",
    :ECYINDRETL => "HH Pop 15 years or over by industry - 44-45 Retail Trade",
    :ECYINDTRAN => "HH Pop 15 years or over by industry - 48-49 Transportation And Warehousing",
    :ECYINDINFO => "HH Pop 15 years or over by industry - 51 Information And Cultural Industries",
    :ECYINDFINA => "HH Pop 15 years or over by industry - 52 Finance And Insurance",
    :ECYINDREAL => "HH Pop 15 years or over by industry - 53 Real Estate And Rental And Leasing",
    :ECYINDPROF => "HH Pop 15 years or over by industry - 54 Professional, Scientific And Technical Services",
    :ECYINDMGMT => "HH Pop 15 years or over by industry - 55 Management Of Companies And Enterprises",
    :ECYINDADMN => "HH Pop 15 years or over by industry - 56 Administrative And Support, Waste Management And Remediation Services",
    :ECYINDEDUC => "HH Pop 15 years or over by industry - 61 Educational Services",
    :ECYINDHLTH => "HH Pop 15 years or over by industry - 62 Health Care And Social Assistance",
    :ECYINDARTS => "HH Pop 15 years or over by industry - 71 Arts, Entertainment And Recreation",
    :ECYINDACCO => "HH Pop 15 years or over by industry - 72 Accommodation And Food Services",
    :ECYINDOSER => "HH Pop 15 years or over by industry - 81 Other Services (Except Public Administration)",
    :ECYINDPUBL => "HH Pop 15 years or over by industry - 91 Public Administration",
    :ECYPOWEMP  => "HH Pop 15 years or over by place of work - Employed",
    :ECYPOWHOME => "HH Pop 15 years or over by place of work - Worked At Home",
    :ECYPOWOSCA => "HH Pop 15 years or over by place of work - Worked Outside Canada",
    :ECYPOWNFIX => "HH Pop 15 years or over by place of work - No Fixed Workplace Address",
    :ECYPOWUSUL => "HH Pop 15 years or over by place of work - Worked At Usual Place",
    :ECYTRAALL  => "HH Pop 15 years or over with usual place of work and no fixed place of work - ",
    :ECYTRADRIV => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Car As Driver",
    :ECYTRAPSGR => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Car As Passenger",
    :ECYTRAPUBL => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Public Transit",
    :ECYTRAWALK => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Walked",
    :ECYTRABIKE => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Bicycle",
    :ECYTRAOTHE => "HH Pop 15 years or over with usual place of work and no fixed place of work - Travel To Work By Other Method",
    :ECYVISVM   => "Household Population - Visible Minority Total",
    :ECYVISCHIN => "Household Population - Visible Minority Chinese",
    :ECYVISSA   => "Household Population - Visible Minority South Asian",
    :ECYVISBLCK => "Household Population - Visible Minority Black",
    :ECYVISFILI => "Household Population - Visible Minority Filipino",
    :ECYVISLAM  => "Household Population - Visible Minority Latin American",
    :ECYVISSEA  => "Household Population - Visible Minority Southeast Asian",
    :ECYVISARAB => "Household Population - Visible Minority Arab",
    :ECYVISWA   => "Household Population - Visible Minority West Asian",
    :ECYVISKOR  => "Household Population - Visible Minority Korean",
    :ECYVISJAPA => "Household Population - Visible Minority Japanese",
    :ECYVISOVM  => "Household Population - Visible Minority All Other Visible Minorities",
    :ECYVISMVM  => "Household Population - Visible Minority Multiple Visible Minorities",
    :ECYVISNVM  => "Household Population - Visible Minority Not A Visible Minority",
    :ECYPIMNI   => "Household Population - Non-Immigrants",
    :ECYPIMIM   => "Household Population - Immigrants",
    :ECYPIMP01  => "Household Population For Period Of Immigration - Before 2001",
    :ECYPIM0105 => "Household Population For Period Of Immigration - 2001 To 2005",
    :ECYPIM0611 => "Household Population For Period Of Immigration - 2006 To 2011",
    :ECYPIM12CY => "Household Population For Period Of Immigration - 2012 To Present",
	:ECYTIMNAM  => "North America",
	:ECYTIMCB   => "Caribbean And Bahamas",
	:ECYTIMCAM  => "Central America",
	:ECYTIMSAM  => "South America",
	:ECYTIMWEU  => "Western Europe",
	:ECYTIMEEU  => "Eastern Europe",
	:ECYTIMNEU  => "Northern Europe",
	:ECYTIMSEU  => "Southern Europe",
	:ECYTIMWAF  => "Western Africa",
	:ECYTIMEAF  => "Eastern Africa",
	:ECYTIMNAF  => "Northern Africa",
	:ECYTIMCAF  => "Central Africa",
	:ECYTIMSAF  => "Southern Africa",
	:ECYTIMWCA  => "West Central Asia And Middle East",
	:ECYTIMEA   => "Eastern Asia",
	:ECYTIMSEA  => "Southeastern Asia",
	:ECYTIMSA   => "Southern Asia",
	:ECYTIMOCE  => "Ocean And Other"
)



###################################
### Home-Work flow journey matrix dictionary

desc_df_hwflows = Dict(
    :DA_I		=> "Unique home DA id (PRCDDA)",
    :DA_J	    => "Unique work DA id (PRCDDA)",
    :Sum_Value  => "Flow Volume of commuters from DA_home to DA_work",
)



###################################
### Schools data dictionary

desc_df_schools = Dict(
    :NAME      => "School name",
    :LONGITUDE => "Longitude",
    :LATITUDE  => "Latitude",
    :CATEGORY  => "School subcategory"
)

SchoolSubcat = Dict(
    :7372001 => "Unspecified",
    :7372002 => "School",
    :7372003 => "Child Care Facility",
    :7372003 => "Child Care Facility",
    :7372004 => "Pre School",
    :7372005 => "Primary School",
    :7372006 => "High School",
    :7372007 => "Senior High School",
    :7372008 => "Vocational Training",
    :7372009 => "Technical School",
    :7372010 => "Language School",
    :7372011 => "Sport School",
    :7372012 => "Art School",
    :7372013 => "Special School",
    :7372014 => "Middle School",
    :7372015 => "Culinary School",
    :7372016 => "Driving School",
    :7377001 => "Unspecified",
    :7377002 => "College/University",
    :7377003 => "Junior College/Community College"
)



###################################
# Schopping centres data dictionary

desc_df_shopping = Dict(
    :NAME => "Shopping Centre Name",
    :LATITUDE  => "Latitude",
    :LONGITUDE => "Longitude",
    :CENTRE_TYPE => "Centre Type",
    :AREA       => "Gross Leaseable Area",
    :TOTSTORES => "Total Number of Stores",
    :PARKING   => "Total Number of Parking Spaces",
    :ANCH_CNT  => "Number of Anchor Stores"
)



###################################
### Recreation complexes data dictionary

desc_df_recreation = Dict(
        :NAME => "Complex name",
        :ARENA => "Arena",
        :INDOOR_POOL => "Indoor Pool",
        :FITNESS => "Fitness Leisure Centre",
        :LOCATION => "Location",
)



###################################
### Popular stores dictionary - based on df_businesses

desc_df_popstores = Dict(
    "7-ELEVEN" => "convinience",
    "DOLLARAMA" => "discount",
    "PETRO-CANADA" => "petrol station",
    "RED RIVER CO-OP LTD" => "petrol station",
    "SHOPPERS DRUG MART" => "drugstore",
    "SAFEWAY" => "supermarket",
    "REXALL PHARMA PLUS" => "drugstore",
    "MAC'S CONVENIENCE STORE" => "convinience",
    "SOBEYS" => "supermarket",
    "HUSKY GAS STATION" => "petrol station",
    "DULUX PAINTS" => "other retail",
    "M&M FOOD MARKET" => "grocery",
    "DOLLAR TREE" => "discount",
    "WALMART SUPERCENTER" => "mass merchandise",
    "GIANT TIGER" => "discount",
    "REAL CANADIAN SUPERSTORE" => "mass merchandise",
    "BULK BARN FOODS" => "other retail",
    "MEDICINE SHOPPE" => "drugstore",
    "CANADIAN TIRE" => "other retail",
    "BRICK" => "other retail",
    "MC MUNN & YATES BUILDING SUPLS" => "other retail",
    "HOME DEPOT" => "other retail",
    "SHELL CANADA" => "petrol station",
    "FOODFARE STORES" => "grocery",
    "HUSKY" => "petrol station",
    "DRUGSTORE PHARMACY" => "drugstore",
    "PRESCRIPTION SHOP" => "drugstore",
    "FAMILY FOODS" => "grocery",
    "JYSK" => "other retail",
    "IGA" => "supermarket",
    "COSTCO WHOLESALE" => "mass merchandise",
    "BEST BUY" => "other retail",
    "NO FRILLS" => "supermarket",
    "IKEA" => "other retail",
    "LEON'S" => "other retail",
    "RONA" => "other retail",
    "VALUE VILLAGE" => "discount",
    "SALVATION ARMY THRIFT STORE" => "discount",
    "MCNALLY ROBINSON BOOKSELLERS" => "other retail",
    "MC NALLY ROBINSON FOR KIDS" => "other retail",
    "UNIVERSITY-WINNIPEG BOOKSTORE" => "other retail",
    "HULL'S FAMILY BOOKSTORE" => "other retail",
    "STAPLES" => "other retail",
    "SAVE-ON-FOODS" => "supermarket",
    "FAMILY FOODS" => "supermarket",
    "DAKOTA FAMILY FOODS" => "supermarket",
    "LOW'S FAMILY FOODS" => "supermarket",
    "LUCKY SUPERMARKET" => "supermarket",
    "GILL'S SUPERMARKET" => "supermarket",
    "BROTHERS PHARMACY LTD" => "drugstore",
    "CD WHYTE RIDGE PHARMACY" => "drugstore",
    "CINDEN PHARMACY" => "drugstore",
    "DAKOTA PHARMACY" => "drugstore",
    "EBBELING PHARMACY" => "drugstore",
    "HEALTH CENTRAL PHARMACY INC" => "drugstore",
    "ISLAND LAKES PHARMACY" => "drugstore",
    "MUNROE PHARMACY" => "drugstore",
    "PEOPLE'S PHARMACY" => "drugstore",
    "VIDEL PHARMACY" => "drugstore",
    "TACHE PHARMACY & MEDICAL SUPLS" => "drugstore",
    "ABERDEEN PHARMACY" => "drugstore",
    "GOOD SHEPHERD PHARMACY" => "drugstore",
    "MANDALAY PHARMACY" => "drugstore",
    "SOUTH SHERBROOK HEALTH CTR" => "drugstore",
    "EMPIRE DRUGS LTD" => "drugstore",
    "MEYER'S DRUGS LTD" => "drugstore",
    "BROWN'S DRUG STORE" => "drugstore",
    "PRESCRIPTION SHOP" => "drugstore",
    "LONDON DRUGS" => "drugstore",
    "PEMBINA DRUGS" => "drugstore",
    "PHARMASAVE ASSINIBOINE PHARM" => "drugstore",
    "OAKFIELD REMEDY'S RX" => "drugstore",
    "POSITIVE HEALTH REMEDY'S RX" => "drugstore",
    "REXALL PHARMA PLUS" => "drugstore",
    "DOMO" => "convinience",
    "CANADIAN TIRE GAS+" => "petrol station",
    "ESSO" => "petrol station",
    "ST ADOLPHE ESSO" => "petrol station",
    "PORTAGE ESSO" => "petrol station",
    "NOTRE DAME ESSO ON THE RUN" => "petrol station",
    "KING EDWARD ESSO" => "petrol station",
    "TAYLOR ESSO" => "petrol station",
    "PEMBINA ESSO ON THE RUN" => "petrol station",
    "ST ANNE'S ROAD ESSO" => "petrol station",
    "TRANSCONIA ESSO" => "petrol station",
    "CHANCELLOR ESSO" => "petrol station",
    "ABAS ESSO" => "petrol station",
    "AIRPORT ESSO" => "petrol station",
    "WAVERLEY ESSO" => "petrol station",
    "KENASTON ESSO" => "petrol station",
    "SETTLER'S ESSO" => "petrol station",
    "ST PAUL ESSO" => "petrol station",
    "SHELL CANADA PRODUCTS" => "petrol station",
    "SHELL FOOD STORE" => "petrol station",
    "SHELL CANADA" => "petrol station",
    "FORREST & MAIN SHELL" => "petrol station",
    "SOUTHDALE SHELL SELECT" => "petrol station",
    "PROVENCHER BLVD SHELL" => "petrol station",
    "REGENT SHELL" => "petrol station"
)



###################################
### Dictionaries for datasets parsing

csv_datasets = Dict(

	"df_business"          => Dict(
		:variables   => desc_df_businesses,
		:NAs         => ["", "NA"],
		:NAs_replace => nothing,
		:rename      => [:BUSNAME => :NAME],
		:new_col     => nothing,
		:filter      => nothing,
		:file_name   => "Businesses2018_CMA602"
		),

	"df_demostat"          => Dict(
		:variables   => desc_df_demographics,
		:NAs         => nothing,
		:NAs_replace => [:ECYHMAMED => 0],
		:rename      => [:PRCDDA => :DA_ID],
		:new_col     => [(combine_cols!,(:HouseholdsWithChildren, [:ECYHFSCWC,:ECYHFSLP], +)),
						 (combine_cols!, (:HouseholdsWithoutChildren, [:ECYBASHHD, :HouseholdsWithChildren], -))],
		:filter      => nothing,
		:file_name   => "DemoStats2018_DA_CMA602"
		),
						
	"df_hwflows"           => Dict(
	    :variables   => nothing,
		:NAs         => nothing,
		:NAs_replace => nothing,
		:rename      => [:Sum_Value => :Flow_Volume],
		:new_col     => nothing,
		:filter      => [filter_df_hwflows!],
		:file_name   => "home_work_flows_Winnipeg_Pij_2018"
		),
		
	"df_shopping"          => Dict(
	    :variables => desc_df_shopping,
		:NAs         => nothing,
		:NAs_replace => nothing,
		:rename      => [:lat => :LATITUDE,
			 		     :lon => :LONGITUDE,
			 		     :centre_nm => :NAME,
			 		     :centre_typ => :CENTRE_TYPE,
			 		     :gla => :AREA,
			 		     :totstores => :TOTSTORES,
			 		     :parking => :PARKING,
			 		     :anch_cnt => :ANCH_CNT],
		:new_col      => [(category_df_shopping!, )],
		:filter      => nothing,
		:file_name   => "ShoppingCentres2018_CMA602"
		),
						 
	"df_recreationComplex" => Dict(
		:variables   => desc_df_recreation,
		:NAs         => nothing,
		:NAs_replace => nothing,
		:rename      => [:_Complex_Name => :NAME,
			 		     :Arena => :ARENA,
		   		 	     :Indoor_Pool => :INDOOR_POOL,
			 		     :Fitness_Leisure_Centre => :FITNESS,
			 		     :Location_1 => :LOCATION],
		:new_col     => [(get_lon_lat!,)],
		:filter      => [filter_df_recreationComplex!],
		:file_name   => "Recreation_Complex" 
		),
							
	"df_schools"           => Dict(
	    :variables   => desc_df_schools,
		:NAs         => nothing,
		:NAs_replace => nothing,
		:rename      => [:SUBCAT => :CATEGORY,
		                 :CentroidX => :LONGITUDE,
					     :CentroidY => :LATITUDE],
		:new_col     => nothing,
		:filter      => [filter_df_schools!],
		:file_name   => "SAMPLE_WinnipegCMA_Schools"
		),
                 
)

derivative_datasets = Dict("df_popstores" => Dict(:source => "df_business",
                                                  :categories => desc_df_popstores,
                                                  :filter => filter_df_popstores!))

shapefile_datasets = Dict("df_DA_centroids" => "Winnipeg DAs PopWeighted Centroids")

prepare_data = Dict(:CSV => csv_datasets, :SHP => shapefile_datasets, :DERIVATIVE => derivative_datasets)