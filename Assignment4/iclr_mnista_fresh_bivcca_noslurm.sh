# Script to do large scale training of imagination models.
#

source preamble.sh

DATASET="affine_mnist"
# TODO(vrama): Put affine mnist at the global dataset path.
# This actually doesnt matter for affine mnist.
DATASET_DIR="${PWD}/data/mnist_with_attributes/"

ROOT_LOG_DIR=${GLOBAL_RUNS_PATH}
SPLIT_TYPE="iid"
EVAL_SPLIT_NAME="val"

ICLR_RESULTS_PATH=${GLOBAL_RUNS_PATH}/imag/iclr_mnista_fresh_${SPLIT_TYPE}
EXP_PREFIX=iclr_mnista_fresh_${SPLIT_TYPE}

MODEL_TYPE=multi
num_training_steps=250000

alpha_x=1
product_of_experts=1
if [ ! -e ${ROOT_LOG_DIR}/${EXP_PREFIX} ]; then
	mkdir ${ROOT_LOG_DIR}/${EXP_PREFIX}
fi

###### BiVCCA models ######
loss_type=bivcca
for num_latent in 10
do
	for bivcca_mu in 0.7 
	do
		for alpha_y in 50
		do
		  for l1_reg in 5e-6
		  do

			JOB_NAME="affine_mnist_loss_"${loss_type}"_poe_"${product_of_experts}"_nl_"${num_latent}"_bmu"${bivcca_mu}"_ax_"${alpha_x}"_ay_"${alpha_y}"_l1_pxyz_"${l1_reg}

			TRAIN_DIR=${ROOT_LOG_DIR}/${EXP_PREFIX}/${JOB_NAME}

			if [ ! -e ${TRAIN_DIR} ]; then
				mkdir ${TRAIN_DIR}
			fi

			MODE_STR="_train_"
			RUN_JOB_STR=${JOB_NAME}"_train_"
			CMD_STRING="python experiments/vae_train.py\
				--dataset affine_mnist \
				--dataset_dir ${DATASET_DIR}\
				--loss_type ${loss_type}\
				--image_likelihood Bernoulli\
				--label_likelihood Categorical \
				--alpha_x=${alpha_x}\
				--alpha_y=${alpha_y}\
				--bivcca_mu=${bivcca_mu}\
				--product_of_experts=${product_of_experts}\
				--train_log_dir ${TRAIN_DIR}\
				--model_type ${MODEL_TYPE}\
				--num_latent ${num_latent}\
				--max_number_of_steps ${num_training_steps}\
				--label_decoder_regularizer ${l1_reg}\
				--alsologtostderr"

			if [[ ${1} == '' ]] || [[ ${1} == 'train' ]]; then
			#sbatch utils/slurm_wrapper.sh "${CMD_STRING}" "${RUN_JOB_STR}" "${MODE_STR}" "${TRAIN_DIR}"
			$CMD_STRING
		  fi	

			MODE_STR="_eval_"
			RUN_JOB_STR=${JOB_NAME}${MODE_STR}
			CMD_STRING="python experiments/vae_eval.py\
				--dataset affine_mnist \
				--dataset_dir ${DATASET_DIR} \
				--split_name val \
				--num_result_datapoints 25 \
				--image_likelihood Bernoulli \
				--label_likelihood Categorical \
				--product_of_experts=${product_of_experts}\
				--model_type ${MODEL_TYPE}\
				--num_latent ${num_latent}\
				--checkpoint_dir ${TRAIN_DIR}\
				--eval_dir ${TRAIN_DIR}\
				--alsologtostderr"

			if [[ ${1} == '' ]] || [[ ${1} == 'eval' ]]; then
			#sbatch utils/slurm_wrapper_cpu_only.sh "${CMD_STRING}" "${RUN_JOB_STR}" "${MODE_STR}" "${TRAIN_DIR}"
			$CMD_STRING
		fi
			

			MODE_STR="_imeval_"
			RUN_JOB_STR=${JOB_NAME}${MODE_STR}

			CMD_STRING="python experiments/vae_imagination_eval.py\
				--input_queries=${PWD}/query_files/mnist_with_attributes_dataset_${SPLIT_TYPE}/query_${EVAL_SPLIT_NAME}_poe_${product_of_experts}.p\
				--model_type multi\
				--dataset affine_mnist \
				--dataset_dir ${DATASET_DIR}\
				--split_name ${EVAL_SPLIT_NAME}\
				--split_type ${SPLIT_TYPE}\
				--image_likelihood Bernoulli\
				--label_likelihood Categorical \
				--product_of_experts=${product_of_experts}\
				--iclr_results_path=${ICLR_RESULTS_PATH}\
				--num_latent ${num_latent}\
				--checkpoint_dir ${TRAIN_DIR}\
				--eval_dir ${TRAIN_DIR}\
				--alsologtostderr"

			if [[ ${1} == '' ]] || [[ ${1} == 'imeval' ]]; then
				 #sbatch utils/slurm_wrapper_cpu_only.sh "${CMD_STRING}" "${RUN_JOB_STR}" "${MODE_STR}" "${TRAIN_DIR}"
				 $CMD_STRING
			 fi
		 done
	 done
  done
done


