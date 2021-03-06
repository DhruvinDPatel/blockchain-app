#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.16.0
docker tag hyperledger/composer-playground:0.16.0 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �cZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T��B���#��E9�������� x�X��������B��,[3�M�&�1����� {�a �Ǆ����_�5Y��F��\���a�5�d�Hm +2�)��1-��Hk��I��1rz�բ�*�CWw<Dt� ˀ��ظ�}\�S��uX�4%��n�t>�{�At<���C�ǚ��_�%��ҽK2�r������j��,�
��yy�����^h�Q^9��qQX���'?Dj��A��ئk)��O���U��\��_$�����~��ʼ��]��~�tz*�y��PE,�Y���)�Ot�t�'�NZ��"`��_7L��B�AY��֌����v	���B`��_7L��TZ؝�ڦq/<���x����~b�������E� Kt��������|���pa.��RUd+��q���w��4��	H�:`g�)<�t�0�0'���62�v������v,���"Lݱ\D�,��5Ǵ�8�����@$hh-��\K')M��؛��i���b�#S�����0)��_RF�u��E+�@�/�ɧk
2l�[�Z�D!!�yY-�j�7�H�)k����&ԌA�m�.iP��R��U��j����ԺȦw���G]�{�5B��*��;�:�P��h(@�`J��a~ I5�5/��~�Y����DΠ.�s�r�2|�p�����iz:0�8��p����������'�Xy��
���ӄhi�����.X�ahFct(`3�B�cv�>c.��Z}��!:6}x�hu��X�<� �,޽ $<G �iv�#�!f{����K�6b��N�
<TNJ��k��0���r/�J�߆��� �	�KҊ�a��V��$6�6�!Lb�b
m����>�O��6[p��MkD���,^�I�=���Ca��N��L[�����X�*B`wb��ާh_]��>��!����R���E1���9��]5�׾����0��{�#h#`#)�55�	Ljـ��e����S:8���66b�VG �9K����P� �A��'���8��Bx'j��*��ϵ �d���� j�)o�x1B��<D�����T4���4�OG6T�4�ri�Za��Oҽ�����oL�E���"`���u����=���(�&����?�NJ��a<���t�{4S,=b�Y��2��ݶ`ͳ�\�"𤁍��3�\i�#f���+�/�J���֯xjB~1���7�J�c��z@�\#"Q[9t��ܬ�,�R�3�rn����rd5�6��l�6rֱ�n�m �׻<���H�/����H���41E�	���gaa��rU�rE.U�Wr��~�r��ch�d�%��F��T�ٕ*����%��,���ڟ�p�Ļ�k$�x��Ne��g�j!��z$Զ�V�MP��8�ۮ!�/^P��,i��l�1�Y� ���3���a'�Fa�G��aמ�<��${����?!ve����-�����ԫ��[دd6���D�XE�P�<�-��\��� �7���g��+R�������t g���&��xTX��"����y�f�����;D�A(�g��v9&<�_ڗ^��0E�'��y�=�;���e��"`v�Sg�Q0k��?��cQ��<���_ܶ��0k���G'��h4�\��↛v�-�ȲLkt,�p��v�f�B]��#��u�x�͵#�R;[��t���y�(���D�l��:���ҾzvIv�H�ݷ�$�KO�F��"z����J�"A�>�B.Gz�X�[!���3M�T�N���<�� d���#�aP����	16����+��=�l!��u;�S��.RL��ce�<�8s&��w���5h>�f(�A3�&�on;��s)d��'㿣Q�[������P�_ɬ��Y���CD���RH�G��U��o^3�p R:��B�&] B|����x'lݻ0-���Q"�U�jm����[���R��Ǻ>i���������W��9��v��`3)-/����̚��C���� 97���K�a,��&�~TFx9�z�H�C�����l�]`*OW��y�u��=ـέ�+n�����ʦe��Au�_�Zn��nb��lmPC�'�w����!�N�l��	90�t�4��ӫ{F�5fHē���J�͚���	��n8��r�������d�T� �'�@~w!������?��?��~���!f�A�Ə:�;�NQ�ǣ����pN����$ ��(�������l�9�c�%E}��P �w�0YFd�GR)0lZ>��`��#bk��>-�T�	����,���+R���^#ߠn�"��u�Qv�?^��B���ʽz����\Nw���%�!h�$�mwri���!_>���F����(�1��g�9(��J��n�x�g��~�1�CS��v�&4�sH�"#��qm�ѕ�+�X���M��y���Z�S�Qn���@uE�m(	Q�"����BN�����8L��8�	(�R���bR�Re!R�Z� �rR�d�;�M�F� ^l��'@2�p	��*��N��hY��I�R���8�7��Pg�悐;�B
m���j� ��@ iV�)o���Ctj�|&�
Y&$��4|aV)<������ �v�' +���<W#�g�T���'̗�����'(t��'��_� E���B�3��[�F �-�Z��`���WL>fO��1e�(�g<E����������b��/ƅ��������0^�]v�#?ME��W�N;5 �~����ːi����;���ҙ2���BD�A'wP5�W�����\�k�k\�O�}��D7�bs��1;d���`��ad�z#R��]wc��`�k����í����<����|��/�?w���$�MOa�l��7<������]�/����yϼ������������_��0������8E��F]�^L�z�.*�D�^K��H��DTT���	�ߐ�چ$��Ƿ�_�e&	��+�������d�"+��w�_��m�����2۴�m��q����
6J����Y��7�D�����aY��tK�^�畿��w+���p��o�o�,�Z��?�<�H;L��6��	��������{ރ��?�p������[��������N�mx̘����/J��r�_\�>;�Qv����ӆ�k�:y\9eXga�����\d�|��-#<>��Tv�%g���Q���c�y�n0mH�Bb�!��v� ��D.�KɕM}k�s���i*%+����%�F�$�}��F��}�u\33-��K5�s��I����`ܞr����ֶ�W3�f>ux�?˜˥d�p�IUR�B����k�W.<ʜeO媗�T҇8OKn�5�v�=��ca�l�"��0�Jf;�?9ϸ'�����}R�Nkw�������d�B�מ���i*�|E�NsB����+9ሤ��4n���8:M��E��*����L��a�<S��#�K%�E!kã��Җ:Ǖ�Q>Y�j~�/�5�B��eN��G�)|]8��g��$G1�^�xTr��$�0�eIG�YG�>��څn��<�-��o'���y1!72۩����ّ����v7vϒE~�uV��ͽn��Z;�=:��X��Q��*�c쵎�z�Z?���n�eM����I���(��9;��b'b�����V*ɽ�,��Ҫ�^&�I�4�r���N)����T��)��J����|jW�%��	t��\2�ְJ{��n�C��5 ��-.���5ᕴ�G����a�p�d�!�3�T����b쭑�4>�*�H܀�	�(i'��霄��Q�w���H#�(K�1�]x�Wͬ���L��O���[��a~� rZ?%&�]�P-�[o:�3��5`///Ñp�=�h�iF����O���O��Kc� ��1��{$���4���f������sw�<��S�}	���t��'������@�N�C7�n昦>f���&�7���m��U,68.���K�Z$��j���ɾ|ȕ�ר�}��]=�F�yi�hn�\)Y.Yݔ]�J�|�u������C�����5�ẍ��j�X��RVGR�pG����Q5M��/ *r$]u�{�
��(�o���cf��]�اn���������c���0�����,�p�����&1�zI̼N3�����"1�zH̼3����1�zG̼�3�7b�u��𘾻�����W�?i��->����>u՗������i����?���WM��RA�/��ez�;�]���C/-�t�!g`�ge��*�d_�ώn��ѫF���s?{�ͷ2HqK'���l)�4M�<��{�s�pچ|���l�w�%v:F���i���t�&%�ԭ�ہ������p��-�3�?v���]��a1���Nߢq�d��:a �:(�4�j�yB��үC{�koB�Y^]C�&���a������{��V�fA�Q]341k�IT��ZhC6�UI?j�Jxq�"�!/��_℞��h�@��>{���ن��	�4��y�l��ڋe��+Ҋ��t�GCP�TC�^0�@�PQF/#�1m�{��?v� �{�QL"�d$y����t�6���;������Wrɂܣp��Q��7� �t��A�ĻiV��"���:蛮���jע�*@� zS���zРS&O[� �|�A�6z|:���@� в`�0$�X.�Ґ�ig�0J��6���Q��	�R����=��8 ���W���3PiR�'?h��:��a��{!��I�63ol<ݧSԟQY��s�ꑻ��4��ci*��?$8�l�������{����k����*yƿ��|y��H�7M�\k��q�v���
�G�aH����CR���U��,dw�@�"�~���m'{�n�8Mk{����S����U%��W�l)���kY���`T�-���޳�8�d53;Mΰ;�w>4�bz�om�3�N�mi3�i;]N��9���t��N�3��-jiFZ��q��=p�� \V �\q��q���tMW�HS1��Ȉ�����!7����,M��_�s	(���P�,w�m���4F�9��JУIi��ODl���\1�>@�xRH��R�iYC��j�C�wՇ^-2��5;�� �����.a/=W�H�?@�>�����+F��ƪ��Ђ������\W@��Lg�������x����7"�C3��J�f�N`*�9�^�M��-g���Y��
�.��T�!lot�/��ƻ��PQs��v]#��:�X�i �"7�9���{˶�{+A��}?N�k�ܭ���~�1������Ǡ��&7GNm��)���
ek\R�͎i,�*��c�x���z����@�l����C��@BۏQ�۸x�O�����?Mw�?n%aē���?����濴����_���O�Ќ���|�����o���~H`��l��ƽ_��+�~�ފ�
��!�����R�d6�j.��j&�ш�Led5I�4��e"��RJ��4*�$I��l�T����cbo����ѷN��O~�ǟ��­}J����Nb��c��c�����M���+
;�7oƾ����~#��7�� ��ƃ���}Mh�c�~?����?��~ַo���+��.�o�kpm\�7ز\d��=�,�Je��]��]?Oj�F��O��:Ʈ{w\c����(^���}g�)cy��A���]��
.���hR8�.��%��$����a&��E~E�����H����\�Ϲ��YLz��R���u4�V�\BCH��qy ����΅��-����`���Eet��vW.�g]2�M�-��q��I�E�.x��jl� �t�a�á�ǯ�Kf�VN�J��z�㊧݉}@���o��65�.�ʍN��7����P��[ĩ;׊�v�R�/p���l�u�QJ04X{�8�,�/���nc
��e]TX�
�]ޭ��	�So�8^o�E�1O36��H�����t:�ze�X����Y�Jw<�&��m��	@6i^�/�'	�}�0]��[�&��3*��tO��򶪰��Ae���⑩���4��N�.���|"����N��&rX�/d�V₻�p)5����|��J��c/�J4{������PZ,;{����G"��1'+"]��p��/ϊ�;k\��XaP�|у�L�Խ����칞�ɺ%� e���r�z���Ѡ���gc�Y̔g�CV�zD5��^Gl+'Ks^�\�DUY%mR8*��)�>�*��T��j�~4%Hk�ZR�j�/?X �E�dz���ӹ.a�6W���j�m�J5�>Y���Q���4N�s�O�.�S��͸B.���Sn�fڬ[w;z�XRI��%�a���*zΚ�ҐԸb���H�{��T�c*�g����Ϗ��􈻀������ﻱ_��b�ؽ�+�ߗ���U�z����
�����kV#|!�=��^n�P�4�e���k������[	�\¿�I�������q�b�@_^��{!��y�b��-ʊ��ؿ}�\r�~����|?����߿~��q)+�� +S�����&�Sg:�*�i�վrF�K����n2?Onӽ�<��r.Iq.�:Z� �g����h�Q΅y���r�Ϻ\g�	L;��5�|�
U��H����gւC`��7���*5�Q(ef�|���N�Zᤁ���Tg~��FD�6�y�[�3Fx�g�4�ɚbO����h;�﬎F��n��Ed]�H�k��"�Ĳ�8�	��e�.�Y����̴��TVoL��dn52:�t�_���e2�T�NZ,�n�e:4���lCP���2m�Ƒ�֏�2!ڣ�!���Q&5<�B�)9ѰGö�`@	��fNp����Āk�������J�?)�
/���t�gË􁇿u)�䡢,��r�[N�|{�f�
���l}6h�����s��m���_�V�+�0P��Qu�G,�*&uĊ\R`���	����eմ@��a�{x�UrǮK��cH�?��~���W�s�(^M�c�-䪜\���mt
ug�Kf�R'�E[�U{lc<ni�Jbo�1��Y�l
c����Q/G���i���㬑?&zU:��V�g��-Ю�(s���h�=����7\ޢ��h!P�ި�x�PZ�u�?��t�`O'(:F2�S�P���Q� �~@��@9�ֵb�P+�:C��N�r+3/cL�ϻ#�'p�E�)��Y1�-���a�d�\��+��p�܀�q'�|����U��3��u)MTE(H�kA"T��d|ddf�c*�@J
g�WfoW�Xn��ɢ�&v�#��"a�]�&&�Z�P�H`;�&T���E����Vy�l����d�N��:�թ�3�rS��'\ަ�2;�5Z�Nr�=qBH&�ku�	�q*D5m���᠘4W�������J��
,�(;J�]銧�=�q:^��F4������D�A�h�Ba��PJ	%q���!��e=U��bFP�a����QnQ��#,e��FX�=��d�vBb�֢�Ϥ��
Lz�4Vx�K�)s)�zJ'ת�f����B�4��K?�}�"z��c�EU���W��\��W�������uѦf;Sû��
>�U���i�6�g���h��c�`/ۖi�Eb?�H�2h+-�F��{��O�>%�~�4��6�*#z��b_����D�=�|�}��w��i������ބ.�J��{��%�c�6u ��j��,3�#��8Xɑ�
-t�9����� }#,�c���C��T�m͎Q��۾�S�*yt<w/���=�￻�y�5���=�����/J����0����������t3��P��j?�]O�=��F��!���n��Sa�Z\CQ��� ��� ����TJ��i*�4���@4��4��L����?"{�|�&Di>�-z����~<��]g������?򿰞U��Q`#t�f�8�Ǐ֧=���5�f����gA^�bتo���D���N��h7,q�cj"_�==��7��-�$h�!��QKPϠ�7��?j=,�q�1�|�,�M��~��J
�h�3��kdLEoշ�9�Dz��Mǁ����G���������T�c�,8(h���3��3o��� d��|m��l�,��4b	�ƣ�{;H❸�?���F��s�h�Ez�c������'u�Ȩw���k�1�����Ά�>�\�B�#5"�p#&~��y6
EA�?Ycض"��E��H���X�����j?�J�
{���+'�!��B��>$�P�����It��nX�cŘH�~�i�'0\[/�N|)��k/$�f�.��+�0���CXW�wTh��)|v��a߉~�X�o=�ME.��"J�kH��Բm��_��`6��?`ТӷME��pi��oѺ�����oqd�dFKȡ!qhg�gA��F��1l�8uZRB��7'q���ת�g@����=D@�Q�ɧ�8ЏǶ�U����!N�?ɚj&�l]+\7#m<M)d��������g�Ah��A*�����8���K��=� 5=C���\�!��}8��C�3;���Z�E���-�����x�E�q���4�V���l�OW2� � 2 �"T�˰.�=ُ��&tx����3�L{��z��D#h�2
�^G06$���^ݨ��HZ��hW �D���P��l����IZ`��G[�e0�3 �a������U��]��N,׳���@�뵩!�`X꺋�=^�8�	в�p.�h��H��[��7	?<���� (|S����c�A���}�Ed�M���n{���v=!A��9�t�i��ZC(@�Q�;0tT&.{�#	�D��ebG Uk"��"r��}7nl9��I���&��c�G�������y�jtт��nAN�1M��P:���<|����8�:�Xs\k:��Ʀ��ܙ��ȱ�RDpގ8��������bG�z����g>�;���6.y�Oe����T2��;����ޏ�O��a��Jv�\�x%
�����pdó~g]��&�?���02ғ��(���|��Q��5�&��J;:��sQ-xyV�+Wh|�k=/X�p�gkG"IU�'��LJ�Ler�&QI-I��龢h}B��	I"�$�?G�r_���R*��$2-���h ؋<n#lya�P��h������xo��AN���WŎ	'̃9Ԗ���Ir��dY�SY<�J*Aj)�r�$�ө����鬖�d���`&�9-��)-i`b�d/��>�9q�T/���m#-2]��=��"%��:	����;�]X
��쬿��%�׸�֚,�X]�\��Wj�
w�U���<��/ƷD�J�l�k���H���-�m�-�K5�	:꿤�n�
N��y�v���tEh�y�I�x��0��.�����s�{�#;V��L8	݂�j	{�$t��d�Kg�j�h;n�}���P�,�ӵQ���0��x'�l��3Z�}@��/8L9�a���{��� ��j��q�-DG��%���k캤G,Ǵ��E�c���k|U|2��D"�Y'��41��}���OT6~0��ӣhـ�ΙMt���7��? UK����U|�ʉ�Z�@ �{��q���f���H�-r=�uZ,����X֋��EP�%����'K�4C��'yk�X���Z;_bL�_�)��*�S�l�h�%��0�?{��䓾d��9$Ll.�7��N�G�!�o����+H>t6�؍l�)k���.�c����O��M��j�/w���|���(�����/w1�	@ls�����F��e���
hb;p*��i����ٶ��������M޳��JQ8y��6��\��4���g^�$NB��w��鹯�}��O������F�R��������;�߷�n���V�넍�K��nc����������e��$�o�*������n�����_	|���M���/��Em��B����Vҝ�;4wh���/���)})�?jG��;��V�m�����.���Y��ɪ�)W�~�R4URr�,�h�,��'�$�IʙTV�qU#R���7��_��e��'���/y��VRD�����������wm͉�]��_��[5�Oo��IEE�7_"�(*(ʯ5�Lϴ�$�� ���*�ʤG1�Y{���3��y�M=v�Hkl/�hWws\���βpx����簍��Y�?۰�;;�[��~���1��	��+|��FxNz���%�`�f�C4�IW���^���;4�����_�t�x4����>|<�?φ��:�Q��������W�&�?�=��I��*P���l`�/�����~��������������6�]�[���_;������4���Vqo�@�U������f�����������hu����m��"�{�g��_�N������G8�����O������m���s�F�?}7��_���Z�P�����'�����߼������O������wC:[9�x��Yֲ��b���i�V?����}ѻ��w?o����v?���|3��(���}��}"k����(s�u�RK�w7��~���Lq鼰��]��en,UG�%Y�B{�3'�nk�#˲�6N�/Nag�0�����{�/k����}v�<ٳ�u�\9����o�G˔bN�:M/��v�X���?�}J��
M�U.�<%�s��s	]���Zю��y �J��$�3M�f���r���r�i�3������m1:7�,�w3����_���D��P�n�����mh�CJT�hD�� �	���+�?A��?A�S����G����Y��]���s�F���g���O�W�F������ф����ë������������O�,�if'���;������KY_���E����G^���]gǶ��O�U?	'���������h�Z��m���d�Q�_lX�UP}UT��J^���YP��x�wX`u�#�0t%{*둿�����S]�<�H� �sI�%�PS�om|䥏��6�u��#S]
ݒ@4���Ӫ�f�m(��v�\�3� �h��`��L2��£�(����\~�Rd��U^��4����Ƙ����������W����%��C����s�&�?��g�)�����I�?_�8,h|`>�9ڧ8�y����9�.H��6 H?�Ȁ	h�'},�����G��Q�?����g��ge��V�XL�h5$K3�t(��n#�-�TtWm}�����%��丹�=Q���W��1���\���vd�컇��<4O�6]n���gV��H�e����%L���訓����ͻ���V4������P���'���M8��������������kX���	�����>����h��}Ԕ�i;���B��h�;�q���lW��
h+���K���If���h�Ƭg\2���^�#Kt�,
+$��R�:�FQF�Tv�V�bwql��dS0E'�"`�ھKC��V4��'���	8����;����0��_���`���`�����?��@#����?��W^�ny��5�QyG�𸙲���+�r�����W������%���e�Um-� ��?p �W=����T:�$X	�*r���; �H���	h����V�[b�����ڨ��
��ޮ,Ku�2 Z�1�Ym*(�K=ϗҹ�ݫz3+�ȷ�U���}7����[����nw �N[,t�Z�Hi�W��7\0 <��F�04:��(�^�^(�$R9ΘHk���e�=o ��R[R{+&�T-?jBB�����4�bJ�2�0�pܵQn~앁ؚʹ�ǳ����H�,��1��V�����GC+��d�$ߤz���{}��Y4ptrY�=m���h���S���
|��x0��\T��_��a��4���Gh�_��}���+A%��~�EU�����4K@�_ ���!������a��&T��p����}�8��{s�� �x����C�.$=~��#	b��!ņ��x!,v~�P�?��}��@�}<~���;���R�9�l�tm�c���,�4�c�d�JM:�2�k�d����ŲJj��[��b�}�;���ݐ�`o��t���l&�1�	����`FǮ�8ߟ$�r��a���6���M8�q���?��T����[�Cݯ�O������g
��*��g�������7�Đ��D �����q����_E����ۗ��vpCP�o�;���W^�������ql�F�2G��%��q���n�;(k����e�[!�%�#�߷�!?2�}ke#�:�]s2ʽ	-<�T�.���w��ig��;�e��b�i<�&+:g�%2�=����'c69���	Zۛ[qL�˺�B��U3}>1.�\:Q��l[���An�\�9���l����qnqsp�#+�"�F�u�m����70���1ѣ���鱗#AWI5%*�L��h�۳�⼒�'<�ܺ-VV���N�b̟�9��EkL�1z�y�N�����γG�������D��in8#��cٕ�	�����ߚP����ݛ
��?��k�8	��5�Z��A�	����o����J ��0���0������$�����s�&�?���C����%� MA#�������_����_������`��W>��?f�_Z��<F��=�?	�%h�v_����U�*�<��B� ��������P3�C8D� ���������+A��!j�?���O?���?*A���!�FU�����?T������G8~��������6Cj���[�5�������� ����Є��Q�	�� � �� �����j�Q#�����������,��p��ш��A�	�� � �� ����������J� ��������?��k�?6���p�{%h����hB������a���������?�8�*� ��/Y�B(�k ���[�5���o>p�Cuh���U�X�2�X�ĸǇ��򹀧2���=, ),�p��xg=��(�f�?��O��&�?��P�ׄ���Ñ:�V@��)����ӽV�¿U�b+��7`���E�/ji����gw �1��Fg�$��-�A9��-q\�C���$e�c�v��.۞Ķ�1�����B���������3��8������G{@����/}�kc�&�e�K_K��U��04������P���'���M8��������������kX���	�����>���o�:}n��h����[�E(uW�y9�\��6><�a�l�/���s�h%F�R��MKu'G�\L�bw��g��V��3;��a�)��ݹ#�{]Hb��Fj�Q�oWåBP���8�����"4���?������
h��������/����/�@���������?�G�?迏�k�o����S���tLJ��l����N���o���������&�d����׏u �?r�w��-����eug;?º8��e?��n6F�v�;�h�`���h�(�V�J(˜�/��0.q?bvTI��gdz'-�{m7���ӷ���G'���M�-�x�,�Hi���;a%�ȫ���hC�s����e~�b��T�C�逴�A9Zv�,�bJj�=�Ξ�������'cn��z#�s��.��ou�kWbQM�$���^���h��9/i��N�Vxܓkt��������+��������#�������C��|��������$N��M��p�A�'�W����Jt��Ƣ�����Oa8�_������)��*P�?�zB�G�P��k����G]9��*��gؒ$�/_�?t�1w�i�u���G�w�v�G[������Y��g�M����^i�����S<Y~�{��x������Y(ї�o�k]z��X���uys.o�%�_cK&�`�Q��iUů��.��m���mI���keLbdHk�d�����w��	�	��\�R#B)[����fJ�y7��q��C&%w<�W.)�S[<�h�'+��}�f/����X1�)��Y��~����o�]T��>s92cQY�?��dK4�۲�B|�m3�ЮI�V!q���(�k�2GFW�EE�Ebُ-N�#�G�������Dpma:��C�A���C<�Z����zba�g�����.2��,1WAe*�خLxk '����^��G���A��"T��X��|'=�]p8Ex��p��m�	�F]f�X����L@X��b>���B�����k����g���L��n~T��������l������>3��ŜX�b�e��^��U� �+7���o�G�����w�h���
4A��,y����������`T��_�����?�_%x���7������9w�Y,���P�є�/�;�ϳ������e�N)�'��f�!������!?��ݬ?���T��o�����~��|?��s�k�%��GFbz-y7�+�!59is~�����n+�`C7֖#H?�]���.%d�bRN7�^����f�!���^l?����J��E�b�YtZҸŲ��I���/�m�ˉ��֥�!�}?!����p��q{�l6c��)K���k�a����f��]������G��6\RI�rO��D]�(4P��B�]���M�ģ��������T2�c�#�[�/`�_�l.|��p��8��{��ښ���S89�Sgʓ��N͞*@@�~�LM� �P�S���m��N';�b��W�Ĉ"�<�y�Z��-F�f%�&5���g�R��oH��������{{~f��Te֞L��֪�v;�ŉ���T7��J�2D�s`��<��}ݶ$��Q������������d��� �/v{����i��Z��+<f������Б����@�pPfHK��p����Y��T�������?��ؙ�E�;�]�.����ͻ����^�a���K�����>J'nxY���n�/E�OD<5���b�296�YY��M��r~���h�뗑+�G��.#W��ҕn�txq -��jב_W�{Y��O�Y8#��mmծ�ɉ�w���qݞ٬�ˑ�x��$-+�w�f8���i��m�Qڜ[r�Ų0mrLo�m6bp����5����x^�Qhp\T;��,x�)��zcwڔbK���^Y�<;�ok��4#��Vڂ�6�Ju��v;ʜkh��1.�My:4��h��<Q��{㋖����!V�n�s8�ҧJrU��B�QD����b�<'�*N�d_�Л�z���7�i����[����TH��74��
����������:����=2�_��d����
0����O��	����ު���.�L��}��,�?���#e��Bp#��U��8����T��oP��A�7����-����_���i|���S8���	�g��C�ϔHG����C��@�A����������
��?�D}� �?�?z�'�����SJ��������O�X�� �O���?ԅ@DZ��}�b���� �����_2��������
(�$����������U����Y��AG&�������?@��� �`��_���B��������GFF��B "��U��8����T��P��?@����7�?��O*���c���@���/�Oݨ� �R!���Q�����#�������d����� ��[�� ��&�������_��H\����CJdB��$�K�֌2E��L�ʤI�6��%�4ْIcX�^��-4e�e�-28C���˓�/2��?��O�����(W'��_�r��5����r�A���˂��8���GZ�7���sZ�̩S�+��/L0_j2��j$[�*��׼���VC�w�d���p�V�$��d�'��vP

S[;�(b�Ě�9S)|_`����V��uڶ$�����-�]o�qvI��J��//�:����I���#�?��D��?\��o�B��:���0�(����q��*�/Y�����3�?^�����mrT�8��|T6L5m{5i	�.�;{һ�5q�l͚��r����o�����4Q�a�p���X���۬�¶ff��K�����v��\mF.e�.ԅ@;���%�����7���/�_�L����/d@��A��A��?D�?��	�G3����/�Y�������_�i����F�Z��#�|��9�'M~��{>�
/�S���%���_v�a/{�8\��Ʀ;��8N�z��W{���g-���OF����[6��v�o�rl�6�xݮ�Z��6V��+jmW)��ߦ��B���G���y��UJئ���\o ��&��mQ�;F�1M!��|gPM��
����$%�M������
�د�|/-���)��8G��tj:[�%��lH��U&5�U���a��L��~�g�I)L�J�|D>��qz�Ҁ*���.���ZՃ�u����{I�AC�'T�u�����Q����5��_��(�I�?��x{2����/�?R���/k�A����������4� ��$	��s@�A���?q#��R���X���G@�A���?uc���M�,�?T�L������?��O���4���P��?�/��č�_������
�H�����_&��@Ff��DB&��:����T�f��)��О�?���o��o�cSd�cffW�Z?��#�:O�����$V`?���|��H>�3�I�����q�\r[���K�����N�	{�"�*�cF�W��)-:X�iS�}mV^��W�I5���ԩ��ֺi���)�%kt�%�vO&i�؏��^�~�y��.���l�Xr^�Y6��͖S�ñ2�z���S&�W�n��r��<.�cY'���z=$�9f��%[��B'X/����6���ÃN�"
s�5����O�n}�,T�`(�U��v����L�?�Gr��bp��������_&�����%�|� �����F�/��S�A�/��������� ��{^���K ��o��	��q�DdH�o�: ޚL��0�ߊ�+�d������v��U�!�w\�4T�v�1�R��������H�/�ͽ���xIS�� ��?�r J�`+��G�j�5���JJE3
�Q�i�k��6i���{fP��p�)��>	��Fq8/��t����zƢ���!�� ,I�39 X��G9 ݈���b�j���,z\�P�}%\��̸*6۲À�ϥ��w�{��w����)�j54	�����^�y���0y��f���_>��a2����@��T@��>-��J�'�߷�˂������i����khEֲ���%͜q��h\g(��I�$�R٤	��5�,�0u�1�%��1���~��2Y��[����t�����)�s(���'S�=aC?���F,��^0�v[����IX�_��<換1Y��������Gv�;���\�0yI+�ܳ�����g*s*9d~q���9��i6���X�,�c� ����p���,��P�H��d(����B��:2��0����i�8D})�,�?�����7ڭF󅤷e�/�p�RXR�h�7�^�JM�3)x|䄝�%�cz��[��
U��\jU"�^ј{���!�W�~avl��]��{��dݠ\��ګM���*���"!�{-�h������h�����������/��B�A��A�����C��Y�4]���o��Q��l�����ǌ�}�*�y|1
[ܽ�����O9 ?���X vY�e@~i;m%2�V�:y�a��jEA�w\�4�X�%sXn�}*c�B�XLKlxd������Ŗ�/���k��z�(M��m�_-~y���a���5.�v�|�x�J-��|gP墤O0���@⣆�e� v+a�$2>��=�y���]-���x���`�1����x���7wy!>��ҏ4��X]����(�O��~��p O!��Km�U�fӓ��'w�.�pǕ==6��������1J���20�a}���^�Iu�תS�3L�.Q���a�n��o�p����!<�������T��>��b�,���s�ts���B3��q������ᨭcE=x?�I�U���$ls��o�ۣ
v~]xHv���7��2s��/�u�
r�1��>lv�����X�>��>���z���(�5�5W�]	��ӓ��˝�'�_l��X��.������Ƽ��O�Pz��̿�3�1�G0������$�&���o�����;nAׂ9��-'�0�qs��a�����Ϝ�;n��V��Yk�,x�3�}0��{*fh���6r�G;�ĸ�P��_;W[�r��W�g���\87s����x3Ǐ_��XE�����?r�,��ox|����^�c�5�
�������������9/�ŏ�b�Oz����ł����:��J����wϭ��y8�W��"�'�f��>̒���Z?W=z��2g����wN.��o��e�kh��7��*�hk��s]ǵs�X��O���9'vf�s����n�c_i��A���^i~�I�n����`�1������kǂ�iz_��YK��ד:��9>��y����&^��O_^�3λ��������i<��/58��34
��W�4��<9Xu�_;����8�����C�Z]�c[����jJ��؞]D���}</S��'%/x���H����?�x�                ��<����� � 