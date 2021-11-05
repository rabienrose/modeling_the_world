from PIL import Image
import os
import shutil
import json

path = "/home/rabienrose/Documents/move/pixel_art/vx/"
path_out="/home/rabienrose/Documents/code/modeling_the_world/test_imgs/"
dirs = os.listdir( path )
if os.path.exists(path_out):
    shutil.rmtree(path_out)
os.mkdir(path_out)
chara_count=0
empty_group_info={}
empty_group_info["hair"]=[]
empty_group_info["eye"]=[]
empty_group_info["skin"]=[]
empty_group_info["cloth"]=[]
empty_group_info["shoe"]=[]
empty_group_info["deco1"]=[]
empty_group_info["deco2"]=[]
empty_group_info["deco3"]=[]

for file in dirs:
    if not "png" in file:
        continue
    im = Image.open(path+file)
    for i in range(4):
        for j in range(2):
            chara_name="chara_"+str(chara_count)
            chara_folder=path_out+chara_name
            os.mkdir(chara_folder)
            im_crop=Image.new(mode="RGBA", size=(32*3, 48*3))
            im_crop_tmp = im.crop((i*32*3, j*48*4, (i+1)*32*3, j*48*4+48*1))
            im_crop.paste(im_crop_tmp,(0,0,32*3,48))
            im_crop_tmp = im.crop((i*32*3, j*48*4+48*1, (i+1)*32*3, j*48*4+48*2))
            im_crop.paste(im_crop_tmp,(0,48,32*3,48*2))
            im_crop_tmp = im.crop((i*32*3, j*48*4+48*3, (i+1)*32*3, j*48*4+48*4))
            im_crop.paste(im_crop_tmp,(0,48*2,32*3,48*3))
            im_crop.save(chara_folder+"/raw.png")
            pattern_data={}
            pattern_data["image_size"]=[32, 48]
            pattern_data["tile_size"]=[3,3]
            pattern_data["raw_name"]=chara_name
            pattern_data["groups"]=[]
            for i in range(9):
                pattern_data["groups"].append(empty_group_info)
            f = open(chara_folder+"/pattern.json",'w')
            json.dump(pattern_data,f)
            chara_count=chara_count+1