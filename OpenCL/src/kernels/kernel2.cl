//#include "kernel2.h"
// void print_output(output_type_cl* a) {
// 	for (int i = 0; i < 3 + 4 + MAX_NUM_OF_LIG_TORSION;i++) {
// 		if (i < 3)printf("position[%d] = %f\n", i, a->position[i]);
// 		else if (i < 7)printf("orientation[%d] = %f\n", i - 3, a->orientation[i - 3]);
// 		else if (i < 3 + 4 + MAX_NUM_OF_LIG_TORSION)printf("lig_torsion[%d] = %f\n", i - 7, a->lig_torsion[i - 7]);
// 	}
// }
//
//void print_change(change_cl* a) {
//	for (int i = 0; i < 3 + 3 + MAX_NUM_OF_LIG_TORSION; i++) {
//		if (i < 3)printf("position[%d] = %f\n", i, a->position[i]);
//		else if (i < 3 + 3)printf("orientation[%d] = %f\n", i - 3, a->orientation[i - 3]);
//		else if (i < 3 + 3 + MAX_NUM_OF_LIG_TORSION)printf("lig_torsion[%d] = %f\n", i - 6, a->lig_torsion[i - 6]);
//	}
//}

// typedef struct {
// 	atom_cl atoms[MAX_NUM_OF_ATOMS];
// 	m_coords_cl m_coords;
// 	m_minus_forces minus_forces;
// 	ligand_cl ligand;
// 	int m_num_movable_atoms;
// } m_cl;

// typedef struct {
// 	lig_pairs_cl pairs;
// 	rigid_cl rigid;
// 	int begin;
// 	int end;
// } ligand_cl;

// typedef struct {
// 	int type_pair_index	[MAX_NUM_OF_LIG_PAIRS];
// 	int a				[MAX_NUM_OF_LIG_PAIRS];
// 	int b				[MAX_NUM_OF_LIG_PAIRS];
// 	int num_pairs;
// } lig_pairs_cl;

// typedef struct { // depth-first order
// 	int		atom_range		[MAX_NUM_OF_RIGID][2];
// 	float	origin			[MAX_NUM_OF_RIGID][3];
// 	float	orientation_m	[MAX_NUM_OF_RIGID][9]; // This matrix is fixed to 3*3
// 	float	orientation_q	[MAX_NUM_OF_RIGID][4];
	
// 	float	axis			[MAX_NUM_OF_RIGID][3]; // 1st column is root node, all 0s
// 	float	relative_axis	[MAX_NUM_OF_RIGID][3]; // 1st column is root node, all 0s
// 	float	relative_origin	[MAX_NUM_OF_RIGID][3]; // 1st column is root node, all 0s
	
// 	int		parent			[MAX_NUM_OF_RIGID]; // every node has only 1 parent node
// 	bool	children_map	[MAX_NUM_OF_RIGID][MAX_NUM_OF_RIGID]; // chidren_map[i][j] = true if node i's child is node j
// 	int		num_children;
	
// } rigid_cl;


// void printRigidCoords(int pos, const rigid_cl *rigid) {
// 	printf("\n rigid = %x", rigid);
// 	for (int current = 1; current < rigid->num_children + 1; current++) {
// 		float *coords = rigid->axis[current];
// 		printf("\n %d %d coords = %g %g %g", pos, current, coords[0], coords[1], coords[2]);
// 		coords = rigid->relative_axis[current];
// 		printf("\n %d %d relative coords = %g %g %g", pos, current, coords[0], coords[1], coords[2]);
// 		int parent = rigid->parent[current];
// 		printf("\n %d %d parent = %d", pos, current, parent);
// 		float *orient = rigid->orientation_m[parent];
// 		printf("\n %d %d orientation = %g %g %g %g %g %g %g %g %g", pos, current,
// 		 orient[0], orient[1], orient[2], orient[3], orient[4], orient[5], orient[6], orient[7], orient[8]);
// 		float *origin = rigid->origin[current];
// 		printf("\n %d %d origin_curr = %g %g %g", pos, current, origin[0], origin[1], origin[2]);
// 		origin = rigid->origin[parent];
// 		printf("\n %d %d origin_parent = %g %g %g", pos, current, origin[0], origin[1], origin[2]);
// 		origin = rigid->relative_origin[current];
// 		printf("\n %d %d relative_origin = %g %g %g", pos, current, origin[0], origin[1], origin[2]);		
// 	}
// }

void m_cl_init_with_m_cl(const __global m_cl* m_cl_old, m_cl* m_cl_new) {
	for (int i = 0; i < MAX_NUM_OF_ATOMS; i++)m_cl_new->atoms[i] = m_cl_old->atoms[i];
	m_cl_new->m_coords = m_cl_old->m_coords;
	m_cl_new->minus_forces = m_cl_old->minus_forces;
	
	//m_cl_new->ligand = m_cl_old->ligand;
	m_cl_new->ligand.begin = m_cl_old->ligand.begin;
	m_cl_new->ligand.end = m_cl_old->ligand.end;
	m_cl_new->ligand.rigid = m_cl_old->ligand.rigid;

	m_cl_new->ligand.pairs.num_pairs = m_cl_old->ligand.pairs.num_pairs;
	for(int i = 0; i < m_cl_new->ligand.pairs.num_pairs; i++) {
		m_cl_new->ligand.pairs.type_pair_index[i] = m_cl_old->ligand.pairs.type_pair_index[i];
		m_cl_new->ligand.pairs.a[i] = m_cl_old->ligand.pairs.a[i];
		m_cl_new->ligand.pairs.b[i] = m_cl_old->ligand.pairs.b[i];
	}
	
	m_cl_new->m_num_movable_atoms = m_cl_old->m_num_movable_atoms;
}



void get_heavy_atom_movable_coords( output_type_cl* tmp, const m_cl* m_cl_gpu) {
	int counter = 0;
	for (int i = 0; i < m_cl_gpu->m_num_movable_atoms; i++) {
		if (m_cl_gpu->atoms[i].types[0] != EL_TYPE_H_CL) {
			for (int j = 0; j < 3; j++)tmp->coords[counter][j] = m_cl_gpu->m_coords.coords[i][j];
			counter++;
		}
		else {
			//printf("\n kernel2: removed H atom coords in get_heavy_atom_movable_coords()!");
		}
	}
	//assign 0 for others
	for (int i = counter; i < MAX_NUM_OF_ATOMS; i++) {
		for (int j = 0; j < 3; j++)tmp->coords[i][j] = 0;
	}
}

// Bubble Sort
//void container_sort(out_container* out) {
//	output_type_cl out_tmp;
//	for (int i = 0; i < out->current_size - 1; i++) {
//		for (int j = 0; j < out->current_size - 1 - i; j++) {
//			if (out->container[j].e > out->container[j + 1].e) {
//				output_type_cl_init_with_output(&out_tmp, &out->container[j]);
//				output_type_cl_init_with_output(&out->container[j], &out->container[j+1]);
//				output_type_cl_init_with_output(&out->container[j + 1], &out_tmp);
//			}
//		}
//	}
//}


//void add_to_output_container(out_container* out, const output_type_cl* tmp) {
//	if (out->current_size <= MAX_CONTAINER_SIZE_EVERY_WI) {
//		out->container[out->current_size - 1] = *tmp;
//		out->current_size++;
//		container_sort(out);
//	}
//	else {
//		out->container[MAX_CONTAINER_SIZE_EVERY_WI - 1] = *tmp;
//		container_sort(out);
//	}
//}

//Generate a random number according to step
float generate_n(__constant float* pi_map, const int step) {
	return fabs(pi_map[step]) / M_PI;
}

bool metropolis_accept(float old_f, float new_f, float temperature, float n) {
	if (new_f < old_f)return true;
	const float acceptance_probability = exp((old_f - new_f) / temperature);
	bool res = n < acceptance_probability;
	return n < acceptance_probability;
}

void write_back(__global output_type_cl* results, const output_type_cl* best_out) {
	for (int i = 0; i < 3; i++)results->position[i] = best_out->position[i];
	for (int i = 0; i < 4; i++)results->orientation[i] = best_out->orientation[i];
	for (int i = 0; i < MAX_NUM_OF_LIG_TORSION; i++)results->lig_torsion[i] = best_out->lig_torsion[i];
	for (int i = 0; i < MAX_NUM_OF_FLEX_TORSION; i++)results->flex_torsion[i] = best_out->flex_torsion[i];
	results->lig_torsion_size = best_out->lig_torsion_size;
	results->e = best_out->e;
	for (int i = 0; i < MAX_NUM_OF_ATOMS; i++) {
		for (int j = 0; j < 3; j++) {
			results->coords[i][j] = best_out->coords[i][j];
		}
	}
}

__kernel
void kernel2(  	__global	m_cl*			m_cl_global,
				__constant	ig_cl*			ig_cl_gpu,
				__constant	p_cl*			p_cl_gpu,
				__constant	float*			rand_molec_struc_vec_gpu,
				__global	float*			best_e_gpu,
							int				bfgs_max_steps,
							unsigned int	num_steps,
							float			mutation_amplitude,
				__constant	random_maps*	rand_maps_gpu,
							float			epsilon_fl,
				__global	float*			hunt_cap_gpu,
				__global	float*			authentic_v_gpu,
				__global	output_type_cl	results[],
							int				search_depth,
							int				e,
							int				total_wi,
							int             offset
)
{
	int gx = get_global_id(0);
	int gy = get_global_id(1);
	int gs = get_global_size(0);

	//int gl = get_global_linear_id();
	int gl = get_global_id(1) * get_global_size(0) + get_global_id(0) + offset;
	
	float best_e = INFINITY;

	for (int gll = gl;
			 gll < e;
			 gll += total_wi
		)
	{
		//if (gll % 100 == 0)printf("\nThread %d START", gll);

		m_cl m_cl_gpu;
		m_cl_init_with_m_cl(m_cl_global, &m_cl_gpu);

		//printRigidCoords(0, &m_cl_gpu.ligand.rigid);

		//printf("\n rand_molec_struc_vec_gpu[0] = %g", rand_molec_struc_vec_gpu[0]);

		output_type_cl tmp; // private memory, shared only in work item
		change_cl g;
		output_type_cl_init(&tmp, rand_molec_struc_vec_gpu + gll * (SIZE_OF_MOLEC_STRUC / sizeof(float)));
		g.lig_torsion_size = tmp.lig_torsion_size;

		//printf("\n tmp.position[0] = %g", tmp.position[0]);

		// BFGS
		output_type_cl best_out;
		output_type_cl candidate;
			
		for (int step = 0; step < search_depth; step++) {
			output_type_cl_init_with_output(&candidate, &tmp);

			//printf("\n candidate.position[0] = %g", candidate.position[0]);

			int map_index = (step + gll * search_depth) % MAX_NUM_OF_RANDOM_MAP;
			mutate_conf_cl(	map_index,
							num_steps,
							&candidate,
							rand_maps_gpu->int_map,
							rand_maps_gpu->sphere_map,
							rand_maps_gpu->pi_map,
							m_cl_gpu.ligand.begin,
							m_cl_gpu.ligand.end,
							m_cl_gpu.atoms,
							&m_cl_gpu.m_coords,
							m_cl_gpu.ligand.rigid.origin[0],
							epsilon_fl,
							mutation_amplitude
			);

			//printf("\n candidate.position[0] = %g", candidate.position[0]);

			//printRigidCoords(1 + step, &m_cl_gpu.ligand.rigid);
			
			bfgs(	&candidate,
					&g,
					&m_cl_gpu,
					p_cl_gpu,
					ig_cl_gpu,
					hunt_cap_gpu,
					epsilon_fl,
					bfgs_max_steps
			);

			//printRigidCoords(100 + step, &m_cl_gpu.ligand.rigid);
			
			float n = generate_n(rand_maps_gpu->pi_map, map_index);
			
			if (step == 0 || metropolis_accept(tmp.e, candidate.e, 1.2, n)) {

				output_type_cl_init_with_output(&tmp, &candidate);

				set(&tmp, &m_cl_gpu.ligand.rigid, &m_cl_gpu.m_coords,
					m_cl_gpu.atoms, m_cl_gpu.m_num_movable_atoms, epsilon_fl);
				
				if (tmp.e < best_e) {
					bfgs(	&tmp,
							&g,
							&m_cl_gpu,
							p_cl_gpu,
							ig_cl_gpu,
							authentic_v_gpu,
							epsilon_fl,
							bfgs_max_steps
					);
					// set
					if (tmp.e < best_e) {
						set(&tmp, &m_cl_gpu.ligand.rigid, &m_cl_gpu.m_coords,
							m_cl_gpu.atoms, m_cl_gpu.m_num_movable_atoms, epsilon_fl);

						output_type_cl_init_with_output(&best_out, &tmp);
						get_heavy_atom_movable_coords(&best_out, &m_cl_gpu); // get coords
						best_e = tmp.e;
					}

				}
			}
			
		}

		// write the best conformation back to CPU
		write_back(&results[gll], &best_out);


		//if (gll % 100 == 0)printf("\nThread %d FINISH", gll);
	}
}
