import pandas as pd
import json ,sys ,re

excel_file_name = sys.argv[1]
phase_no = sys.argv[2]
release_number = sys.argv[3]

sheet_name = 'Override Sheet'

print("[[ INFO :: Validating " + excel_file_name + " ]]")

def get_indexes_override_sheet(column_heading):
    if 'stack-env' in column_heading:
        stack_env_index = column_heading.index('stack-env')
    else:
        print("ERROR!! : stack-env details not found ")
        return False,[]
    
    if 'services' in column_heading:
        service_index = column_heading.index('services')
    else:
        print("ERROR!! : services details not found")
        return False,[]
    
    if 'params' in column_heading:
        params_index = column_heading.index('params')
    else:
        print("ERROR!! : params details not found")
        return False,[]

    return True,[stack_env_index,service_index,params_index]

data = {}

try:
    
    overrideSheetdf = pd.read_excel(excel_file_name,sheet_name=sheet_name,na_filter=False)
    column_heading_override_sheet =[elem.lower().strip() for elem in  list(overrideSheetdf.columns)]
    status,override_sheet_headings = get_indexes_override_sheet(column_heading_override_sheet)
    
    if status == True:
        stack_env_index,service_index,params_index =  override_sheet_headings
    else:
        sys.exit()

    for row in overrideSheetdf.values:
        stack_env,service,params = row[stack_env_index].strip() , row[service_index].strip(), row[params_index].strip()
        if stack_env not in data:
            data[stack_env] = {}

        data[stack_env][service] = {}

        for param in params.split(';'):
            key_value = param.split(':',1)
            if len(key_value) == 2:
                if key_value[0] in data[stack_env][service]:
                    print('ERROR!! : Repeated '+ key_value[0] + ' key for ' + stack_env + ',' + service  +' in Override Sheet')
                    sys.exit()
                else:
                    data[stack_env][service][key_value[0]]=key_value[1]
            else:
                print('ERROR!! : Invalid key value pair ' + key_value[0] + ' for ' + stack_env +',' +service + ' in Override Sheet')
                sys.exit()

    json_data = json.dumps(data,indent=2)

    file_name = release_number+'-'+phase_no+'_'+'override.json'
    print("[[ INFO :: Creating " + file_name + " ]]")
    with open(file_name,'w') as file:
        file.write(json_data)
    print("[[ INFO :: Valid metadata " + file_name + " generated ]]")

except KeyError as e:
    print('ERROR!! : ',e)

except IndexError as e:
    print('ERROR!! : ',e)
    
except PermissionError as e:
    print('ERROR!! : ',e)

except FileNotFoundError as e:
    print('ERROR!! : ',e)