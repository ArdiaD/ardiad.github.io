blogdown::build_site()
file = list.files("../",recursive = FALSE)
file = file[!stringr::str_detect(file,"src")]
file = file[!stringr::str_detect(file,"WebSite\\.Rproj")]
unlink(x = paste0("../",file), recursive = TRUE)

file = list.files("public/")
file.copy(paste0("./public/",file),to = "../",recursive = TRUE)
file.create('../.nojekyll')
unlink("public",recursive = TRUE)
