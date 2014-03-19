delimiter $$

drop procedure proc_merge_good_all$$

create procedure proc_merge_good_all(
    in i_store_id int(10) unsigned,
    in i_default_image varchar(255),
    in i_price decimal(10,2),
    in i_good_http varchar(100),
    in i_store_name varchar(255),
    in i_goods_name varchar(255),
    in i_add_time varchar(255),
    out o_retcode int)
begin
    declare v_good_id int(10) unsigned;
    declare pos int(10);

    select goods_id into v_good_id from ecm_goods where good_http=i_good_http and store_id=i_store_id limit 1;

    set o_retcode = -1;

    if v_good_id is not null then
       update ecm_goods set goods_name=i_goods_name, default_image=i_default_image, price=i_price, good_http=i_good_http where goods_id=v_good_id;
       set o_retcode = 1;
    else
       insert into ecm_goods(store_id, goods_name, default_image, price, good_http, add_time) values (i_store_id, i_goods_name, i_default_image, i_price, i_good_http, i_add_time);
       set o_retcode = 2;
    end if;

    select i_store_name, i_goods_name, o_retcode;

end$$

delimiter ;
