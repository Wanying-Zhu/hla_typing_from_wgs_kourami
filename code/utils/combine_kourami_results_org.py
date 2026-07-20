'''
Combine individual Kourami result, and save each HLA gene to a separate file.

Usage Example:
    python /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code/utils/combine_kourami_results.py <path to kourami output folder> <hla genes separated by comma> <path to output_prefix>

    python /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code/utils/combine_kourami_results.py \
            "/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/output/kourami_output_examples" \
            "A,B,C,DQA1,DQB1,DRB1" \
            "./AGD250k.kourami.imgt_v3.24"
    
    python /data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/code/utils/combine_kourami_results.py \
            "/DC3/AGD250k_HLA_typing/individual_hla_results/kourami_run_3.24" \
            "A,B,C,DQA1,DQB1,DRB1,DPB1" \
            "/data100t1/home/wanying/BioVU/20260305_AGD_250k_HLA_typing/output/kourami_result_combined_agd250k/AGD250k.kourami.imgt_v3.24"
'''

import os
import pandas as pd
import sys

def split_one_result(df:pd.DataFrame):
    '''
    Split one output file by HLA gene, and return reformatted string for each gene.
    Params:
    - df: a dataframe of a single result from Kourami run
    Return:
    - dict_output_strs: a dictionary of reforamtted output line for each gene, as gene:line.
    '''
    df['HLA_gene'] = df[0].apply(lambda x: x.split('*')[0])
    dict_output_strs = dict()

    for gene, df_single_gene in df.groupby('HLA_gene'):
        output_str = ''
        for col in df_single_gene.columns[:-1]: # Skip the last col as it is HLA_gene
            output_str += '\t'.join(df_single_gene[col]) + '\t'
        dict_output_strs[gene] = output_str.strip()+'\n'
    return dict_output_strs


def combine_individual_results(result_path:str='/DC3/AGD250k_HLA_typing/individual_hla_results/kourami_run_3.24',
                               hla_genes:list=['A', 'B', 'C', 'DQA1', 'DQB1', 'DRB1'],
                               output_prefix:str='./AGD250k.kourami.imgt_v3.24') -> pd.DataFrame:
    '''
    Params:
    - result_path: a directory to kourami results. The funciton expects each individual to have a folder with all files stored.
                   The function will look for result files as <result_path>/<sample_id>/<sample_id>_out.result.
    - hla_genes: the HLA genes to call. The default 6 are A, B, C, DQA1, DQB1,and DRB1.
                 If a HLA gene is not in the result, still keep that one but fill with NAs
                 Kourami can output additional HAL genes with flag `-a`,
                 but it may consume too much resource so I skip other genes for IMGT version >v3.24 (the default version).
    Return:
    - Output combined results to files. One HLA gene per file for all samples.
      Also save samples with invalid result file or unable to be processed to a separate file for future refrence.
    '''
    c_total, c_invalid_result = 0, 0
    hla_genes = set(hla_genes) # In case there are duplicates
    dict_output_fhs = {}
    header = 'grid\tallele1\tallele2\t#BasesMatched_a1\t#BasesMatched_a2\tIdentity_a1\tIdentity_a2\tassembled_length_a1\tassembled_length_a2\tIMGT_DB_allele_length_a1\tIMGT_DB_allele_length_a2\tcombined_bottleneck_weight_a1\tcombined_bottleneck_weight_a2\tbottleneck_weight_path1_a1\tbottleneck_weight_path1_a2\tbottleneck_weight_path2_a1\tbottleneck_weight_path2_a2\n'
    for gene in hla_genes:
        dict_output_fhs[gene] = open(f'{output_prefix}.HLA_{gene}.txt', 'w')
        dict_output_fhs[gene].write(header)
    
    # Save samples with invalid result file to a separate file for future refrence
    fn_invalid_samples = f'{output_prefix}.invalid_samples.txt'
    fh_invalid_samples = open(fn_invalid_samples, 'w')
    fh_invalid_samples.write('sample_id\tresult_file\treason\n')

    for sample_id in os.listdir(result_path):
        c_total += 1
        result_file = f'{result_path}/{sample_id}/{sample_id}_out.result'

        # Keep sample with invalid results to a separate file
        try:
            df_result = pd.read_csv(result_file, sep='\t', dtype=str, header=None)
        except:
            fh_invalid_samples.write(f'{sample_id}\t{result_file}\tinvalid_input\n')
            c_invalid_result += 1

        # Get result for each individual and write to output
        try:
            dict_strs = split_one_result(df_result)
        except:
            # Write samples with failed line split to the invalid file for future refrence
            fh_invalid_samples.write(f'{sample_id}\t{result_file}\tunable_to_split\n')
            c_invalid_result += 1
            continue

        for gene in hla_genes:
            try:
                dict_output_fhs[gene].write(sample_id + '\t' + dict_strs[gene])
            except:
                # print(f'# HLA gene {gene} not found in result file for sample {sample_id}, fill with NAs')
                na_row = '\t'.join(['NA'] * (len(header.split('\t'))-1))
                dict_output_fhs[gene].write(sample_id + '\t' + na_row+'\n')

        if c_total%50 == 0:
            print(f'\rProcessed (invalid/total individual): {c_invalid_result}/{c_total}', end='', flush=True)
            if c_total%1000 == 0:
                fh_invalid_samples.flush()
                for gene in hla_genes:
                    dict_output_fhs[gene].flush()

    for gene in hla_genes:
        dict_output_fhs[gene].close()
    fh_invalid_samples.close()

if __name__ == '__main__':
    result_path = sys.argv[1]
    hla_genes = sys.argv[2].split(',') # Assume HLA genes are separated by comma
    output_prefix = sys.argv[3]
    combine_individual_results(result_path=result_path,
                               hla_genes=hla_genes,
                               output_prefix=output_prefix)
    print('# Done')

