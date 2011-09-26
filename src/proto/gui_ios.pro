/* gui_ios.m */
void gui_mch_prepare __ARGS((int *argc, char **argv));
void gui_macvim_after_fork_init __ARGS((void));
int gui_mch_init_check __ARGS((void));
int gui_mch_init __ARGS((void));
void gui_mch_exit __ARGS((int rc));
int gui_mch_open __ARGS((void));
void gui_mch_update __ARGS((void));
void gui_mch_flush __ARGS((void));
int gui_mch_wait_for_chars __ARGS((int wtime));
void gui_mch_clear_all __ARGS((void));
void gui_mch_clear_block __ARGS((int row1, int col1, int row2, int col2));
void gui_mch_delete_lines __ARGS((int row, int num_lines));
void gui_mch_draw_string __ARGS((int row, int col, char_u *s, int len, int flags));
void gui_mch_insert_lines __ARGS((int row, int num_lines));
void gui_mch_set_fg_color __ARGS((guicolor_T color));
void gui_mch_set_bg_color __ARGS((guicolor_T color));
void gui_mch_set_sp_color __ARGS((guicolor_T color));
guicolor_T gui_mch_get_color __ARGS((char_u *name));
void gui_mch_def_colors __ARGS((void));
/* vim: set ft=c : */
