# There is a file with CRAM IDs on the ICA from 2025_q1_realase: agd_cram_file_ids_from_2025_q1_release.tsv
# The file contains file IDs to AGD250k CRAMs that may need to be convert to actual path
# For example: Get details of a specific file by file ID:
# icav2 projectdata get fil.e1d940195cfb4506496a08dd5cea6966 \
#     --project-id 5b12d2b6-d3fc-4c34-905e-28acd9a42926

# Process and combine individual files
import pandas as pd
import glob

result_path = '/DC3/AGD250k_CRAM_info_only/individual_info'
lst_sample_id, lst_file_path = [], []
c = 0
for fn in glob.glob(f'{result_path}/*.txt'):
    lst_sample_id.append(fn.split('/')[-1].split('.ica_info.')[0])
    with open(fn) as fh:
        file_path = 'NA'
        for line in fh:
            if line.startswith('details.path'):
                file_path = line.split('details.path')[-1].strip()
                break
        lst_file_path.append(file_path)
    c += 1
    if c%50==0:
        print(f'\r# CMD written: {c}', end='', flush=True)
print(f'\r# Files processed: {c}')
print('# Done')

df_path = pd.DataFrame({'sample_id':lst_sample_id, 'file_path':lst_file_path})
output_fn = '/DC3/AGD250k_CRAM_info_only/agd250k_file_path_on_ica.txt'
df_path.to_csv(output_fn, sep='\t', index=False)
