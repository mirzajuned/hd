module OpdRecords
  module CloningService
    
    def self.unset_vision(opdrecord)
      ['r', 'l'].each do |eyeside|
        ['unaided','ua_near','ua_s','ua_i','ua_n','ua_t','pinhole','glasses','near','lens','unaided_p','ua_near_p','pinhole_p','pinhole_ni','glasses_p','near_p','lens_p'].each do |ele|
          opdrecord.send("#{eyeside}_visualacuity_#{ele}=",nil)
        end
  
        ['','_unaided','_pinhole','_lens'].each do |ele|
          opdrecord.send("#{eyeside}_visualacuity_comments#{ele}=",nil)
        end
      end
      opdrecord.no_right_va_advised = opdrecord.no_left_va_advised = nil
      return opdrecord
    end

    def self.unset_examination(opdrecord)
      
      #general
      opdrecord.r_local_examination_normal = opdrecord.l_local_examination_normal = nil
      opdrecord.generalexaminationcommoncomments = nil
      opdrecord.refractioncommoncomment = nil
      opdrecord.generalexamination = nil
      opdrecord.squint_evaluation = nil
      opdrecord.specs_prescription = nil
      opdrecord.fixation_r = opdrecord.fixation_l = nil
      opdrecord.distance = nil
      opdrecord.near = nil
      opdrecord.cover_test_distance = nil
      opdrecord.cover_test_near = nil
      opdrecord.stereopsis = nil
      opdrecord.stereopsis_chart = nil
      opdrecord.lens_emergency_status
      opdrecord.squintcomments = nil

      patient = Patient.find_by(id: opdrecord.patientid)
      patient.one_eyed = nil
      patient.save!
      
      ['r','l','m'].each do |eyeside|
        (1..14).to_a.each do |num|
          opdrecord.send("#{eyeside}_squint_select_#{num}=",nil)
          opdrecord.send("#{eyeside}_squint_input_#{num}=",nil)
        end
      end
      
      ['r','l'].each do |eyeside|
        #All normal assigning
        ['appendages','appendages_tests','appearance','conjunctiva','cornea','anteriorchamber','pupil','iris','lens','extraocularmovements','iop','gonioscopy','fundus','contact_lens'].each do |ele|
          opdrecord.send("#{eyeside}_#{ele}=","Normal")
        end

        #Appearance
        ['phthisisbulbi','anophthalmos','micropththalmos','artificial','proptosis','dystopia','injured','swollen'].each do |ele|
          opdrecord.send("#{eyeside}_appearance_#{ele}=",nil)
        end

        #Appendages
        ['eyelids','eyelashes','lacrimalsac'].each do |ele|
          ['chalazion','ptosis','swelling','entropion','ectropion','mass','meibomitis','trichiasis','dystrichiasis','swelling','regurgitation'].each do |sub_ele|
            opdrecord.send("#{eyeside}_appendages_#{ele}_#{sub_ele}=",nil)
          end        
        end

        #Squint Examination
        (1..2).to_a.each do |num|
          ['near_squint','pd_squint','sd_squint'].each do |ele|
            opdrecord.send("#{eyeside}_#{ele}_select_#{num}=",nil)
            opdrecord.send("#{eyeside}_#{ele}_input_#{num}=",nil)
          end
        end

        opdrecord.send("#{eyeside}__appendages_syringing=",nil)

        ['appendages','cornea','fundus','corneaslit','lens'].each do |ele|
          ['','_present','_full','_thumb'].each do |diagram|
            opdrecord.send("#{eyeside}_#{ele}_diagram#{diagram}=",nil)
          end
        end

        #Conjuctiva
        ['congestion','foreign_body','tear','conjuctival_blib','subconjunctival_haemorrhage','follicles','pinguecula','papillae','pterygium','phlycten','discharge'].each do |sub_ele|
          opdrecord.send("#{eyeside}_conjunctiva_#{sub_ele}=",nil)
        end

        #Cornea
        ['size','shape','surface','schirmer_dimension1','schirmer_time1','schirmer_dimension2','schirmer_time2'].each do |sub_ele|
          opdrecord.send("#{eyeside}_cornea_#{sub_ele}=",nil)
        end
        opdrecord.send("#{eyeside}_fluorescein_staining=",nil)
        opdrecord.send("#{eyeside}_corneal_sensation=",nil)

        #Anterior Chamber
        ['depth','cells','flare','hyphema','hypopyon','foreignbody'].each do |sub_ele|
          opdrecord.send("#{eyeside}_anteriorchamber_#{sub_ele}=",nil)
        end

        #Pupil
        ['_shape','size','_reaction_to_light_direct','_reaction_to_light_consensual','_rapd'].each do |sub_ele|
          opdrecord.send("#{eyeside}_pupil#{sub_ele}=",nil)
        end

        #Iris
        ['shape','neovascularisation','synechiae','peripheraliridotomy'].each do |sub_ele|
          opdrecord.send("#{eyeside}_iris_#{sub_ele}=",nil)
        end

        #Lens
        ['nature','position','size'].each do |sub_ele|
          opdrecord.send("#{eyeside}_lens_#{sub_ele}=",nil)
        end

        #Extraocular movements & squint
        ['uniocular','binocular','prism','squint'].each do |sub_ele|
          opdrecord.send("#{eyeside}_extraocularmovements_#{sub_ele}=",nil)
        end

        #Genioscopy
        (1..3).to_a.each do |ele|
          ['superior','temporal','nasal','inferior'].each do |sub_ele|
            opdrecord.send("#{eyeside}_gonioscopy_eye_#{sub_ele}_d#{ele}=",nil)
          end
        end
        opdrecord.send("#{eyeside}_gonioscopy_comment=",nil)

        #Fundus
        ['pvd','media','optdiscsize','cup_disc_ratio','bloodvessel','macula','vitreous','retinal_detachment','lesions'].each do |sub_ele|
          opdrecord.send("#{eyeside}_fundus_#{sub_ele}_select=",nil)
          opdrecord.send("#{eyeside}_fundus_#{sub_ele}_comment=",nil)
        end
        opdrecord.send("#{eyeside}_fundus_cupratio_comment=",nil)
        opdrecord.send("#{eyeside}_fundustext_comment=",nil)

        #Lens Examination
        ['keratometry','lid_margin','tear_film','surface','coverage','blink','lag','push_up','rotation','sphere_test','cylinder','lens_axis','lens_vision','lens_company','lens_brand','lens_color'].each do |ele|
          opdrecord.send("#{eyeside}_contact_#{ele}=",nil)
        end

        #Only Orthoptics
        ['hirschberg_test','cover_test','alternate_cover_test','patterns','prism_bar_cover_test','prism_bar_cover_test_select','prism_bar_reflex_test','prism_bar_reflex_test_select','prism_bar_reflex_test','worth_four_dot_test','nystagmus','maddox_test','stereopsis','hess_screen_test'].each do |ortho_ele|
          opdrecord.send("#{eyeside}_#{ortho_ele}=",nil)
        end

        (1..6).to_a.each do |num|
          opdrecord.send("#{eyeside}_ocular_movement#{num}=",nil)
        end
        
        #Intraocular 
        opdrecord.send("#{eyeside}_intraocularpressure=",nil)
        opdrecord.send("#{eyeside}_iop_method=",nil)

        #Comments
        ['appearance','appendages','squint','motorevaluation','lacrimalpatency','schirmers','gonioscopy','cornea','pupil','lens','extraocularmovements','iop','fundus','eyelids','conjunctiva','corneaquick','sclera','anteriorchamber','iris','pupilquick','lensquick','vitreousquick','fundusquick','opticdiscquick','maculaquick','peripheralretinaquick','tonometry'].each do |ele|
          opdrecord.send("#{eyeside}_#{ele}_comments=",nil)
        end
      end

      #Lens Examination
      opdrecord.r_exam_contact_lens_conjuctiva = opdrecord.l_exam_contact_lens_conjuctiva = nil
      opdrecord.r_exam_contact_lens_cornea = opdrecord.l_exam_contact_lens_cornea = nil

      #Paedratics & Orthoptics
      opdrecord.paediatric_general_appearance = nil
      opdrecord.paediatric_head_posture = nil
      opdrecord.paediatric_nutritional_status = nil
      opdrecord.paediatric_height = opdrecord.paediatric_weight = nil
      
      #Only Orthoptics
      opdrecord.head_posture = nil
      opdrecord.head_posture_degree = nil
      opdrecord.face_turn = nil
      opdrecord.face_turn_degree = nil
      opdrecord.head_tilt = nil
      opdrecord.head_tilt_degree = nil

      #Trauma
      opdrecord.r_ocular_trauma_injury = opdrecord.l_ocular_trauma_injury = nil
      opdrecord.examination = nil
      return opdrecord
    end

    def self.unset_glass_prescription_values(opdrecord)
      ['r', 'l'].each do |eyeside|
        ['distant', 'add', 'near'].each do |ele|
          ['sph', 'cyl', 'axis', 'vision'].each do |sub_ele|
            opdrecord.send("#{eyeside}_glassesprescriptions_#{ele}_#{sub_ele}=",nil)
          end
        end
  
        ['comments', 'typeoflens', 'ipd', 'framematerial', 'lenstint', 'lensmaterial'].each do |ele|
          opdrecord.send("#{eyeside}_acceptance_#{ele}=",nil)
        end
      end
      opdrecord.glassesprescriptions_show_add = nil
      return opdrecord
    end

    def self.unset_clinical_details_assessment(opdrecord)
      opdrecord.opdrecord_chiefcomplaint = nil
      opdrecord.chiefcomplaintselectedtagnames = nil
      opdrecord.chiefcomplaintselectedtags = nil
      return opdrecord
    end

    def self.unset_refraction_values(opdrecord,clone_glass,clone_vision)

      if !clone_glass
        opdrecord = OpdRecords::CloningService.unset_glass_prescription_values(opdrecord)
      end
  
      if !clone_vision
        opdrecord = OpdRecords::CloningService.unset_vision(opdrecord)
      end
  
      opdrecord.postop_comment = nil
  
      ['r','l'].each do |eyeside|
        ['sph','vision','cyl','axis','ucva','va_ph'].each do |sub_ele|
          ['distant','add','near'].each do |ele|
            #Dry Refraction
            opdrecord.send("#{eyeside}_refraction_#{ele}_#{sub_ele}=",nil)
            
            #Refraction (Dilated)
            opdrecord.send("#{eyeside}_dilatedrefraction_#{ele}_#{sub_ele}=",nil)
  
            #PGP
            opdrecord.send("#{eyeside}_pgp_#{ele}_#{sub_ele}=",nil)
  
            #Intermediate Glasses Prescription
            opdrecord.send("#{eyeside}_intermediate_glasses_prescriptions_#{ele}_#{sub_ele}=",nil)
  
            #Near PGP (Vietnam)
            opdrecord.send("#{eyeside}_near_pgp_#{ele}_#{sub_ele}=",nil)
  
            #PMT Refraction
            opdrecord.send("#{eyeside}_pmtrefraction_#{ele}_#{sub_ele}=",nil)
          end
  
          #Auto Refraction (Dry)
          ['dry','dry1','dry2'].each do |ele|
            opdrecord.send("#{eyeside}_autorefraction_#{ele}_#{sub_ele}=",nil)
          end
  
          #Auto Refraction (Dilated)
          ['dilated1','dilated2','dilated3'].each do |ele|
            opdrecord.send("#{eyeside}_autorefraction_#{ele}_#{sub_ele}=",nil)
          end
  
          #PMT
          ['','_row2','_row3'].each do |ele|
            opdrecord.send("#{eyeside}_dilatedretinoscopy_pmt_#{sub_ele}#{ele}=",nil)
          end
        end
        
        #Intermediate Glass Prescriptions (Other Values)
        ['comments', 'typeoflens', 'ipd', 'framematerial', 'lenstint', 'lensmaterial'].each do |ele|
          opdrecord.send("#{eyeside}_intermediate_acceptance_#{ele}=",nil)
        end
        opdrecord.send("intermediate_glasses_prescriptions_show_add=",nil)
        
        #Rectroscopy
        ['top_va1','right_ha2','bottom_va2','left_ha1','va','ha','distance',''].each do |sub_ele|
          opdrecord.send("#{eyeside}_dilated_retinoscopy_#{sub_ele}=",nil)
        end
        
        #Keratometry
        ['distant_kh','distant_axis','near_kv','near_axis'].each do |sub_ele|
          opdrecord.send("#{eyeside}_keratometry_#{sub_ele}=",nil)
        end
  
        #Lens template
        #Occular Assessment, Trial Lens, Fit Assessment, Final Recommendation
        ['keratometry','lid_margin','contact_lens_conjunctiva','tear_film','contact_lens_cornea','trial_1','trial_2','trial_3','fluoresce','blink','contact_lens_pupil','vision','sphere','cylinder','axis','vision_over_reaction','device_1','device_2','device_3'].each do |sub_ele|
          opdrecord.send("#{eyeside}_#{sub_ele}=",nil)
        end
  
        #contact lens prescription
        ['bc','dia','sph','cyl','axis','add','color','types'].each do |sub_ele|
          opdrecord.send("#{eyeside}_contactlens_#{sub_ele}=",nil)
        end
  
        #LVA Problems and Device Reference Table
        ['bvhv','pgbv','aa','txcm','ctl','cvl','ardm','med','nsg','ctk','smbsb','nsg2','lpv','gorp','mfsis','sntc'].each do |sub_ele|
          opdrecord.send("#{eyeside}_problem_#{sub_ele}=",nil)
        end
  
        #Distance
        (1..4).to_a.each do |num|
          ['device','vision','activity','remark'].each do |sub_ele|
            opdrecord.send("#{eyeside}_distance_trial#{num}_#{sub_ele}=",nil)
          end
        end
  
        #Virtual Needs
        ['distance','intermediate','near','special'].each do |sub_ele|
          ['current','planned'].each do |ele|
            opdrecord.send("#{eyeside}_virtual_#{ele}_#{sub_ele}=",nil)
          end
        end
  
        #Dry Net Retinoscopy (Vietnam), PMT Net Retinoscopy (Vietnam), Dilated Net Retinoscopy (Vietnam)
        ['retinoscopy','retinoscopy_pmt','retinoscopy_dilated'].each do |ele|
          ['sph','cyl','axis','reflex','distance','drug_used'].each do |sub_ele|
            opdrecord.send("#{eyeside}_#{ele}_#{sub_ele}=",nil)
          end
        end
  
        #PMT Auto Refraction
        ['','1','2'].each do |ele|
          ['sph','cyl','axis'].each do |sub_ele|
            opdrecord.send("#{eyeside}_autorefraction_pmt#{ele}_#{sub_ele}=",nil)
          end
        end
  
        #Comments
        ['refraction','dilatedrefraction','retinoscopy','fit','over_reaction','contactlens','pgp','retinoscopy_pmt','retinoscopy_dilated'].each do |sub_ele|
          opdrecord.send("#{eyeside}_#{sub_ele}_comments=",nil)
        end
        #Amsler comment (exception)
        opdrecord.send("#{eyeside}_amsler_comment=",nil)
    
        #Refraction (Dilated) drug used
        opdrecord.send("#{eyeside}_dilatedrefraction_drug_used=",nil)
  
        #color vision
        opdrecord.send("#{eyeside}_color_vision=",nil)
  
        #Orthoptics
        opdrecord.send("#{eyeside}_orthoptics=",nil)
  
        #contrast sensitivity
        opdrecord.send("#{eyeside}_contrastsensitivity=",nil)
  
        #PGP (Vietnam)
        opdrecord.send("#{eyeside}_pgp_typeoflens=",nil)
      end
  
      #PostOP Record
      opdrecord.postoprecord = nil
  
      #Spectacles (Vietnam)
      opdrecord.pgp_duration = nil
      opdrecord.pgp_duration_option = nil
      opdrecord.pgp_glasses = nil
      opdrecord.pgp_dboc = nil
      opdrecord.pgp_frame_condition = nil
      opdrecord.pgp_lens_condition = nil
      opdrecord.pgp_frame_material = nil
      opdrecord.pgp_lens_material = nil
      opdrecord.add_pgp_near = nil
      opdrecord.duochrome = nil
      opdrecord.jcc = nil
      opdrecord.dilation_drop = nil
      opdrecord.add_pgp_near = nil
  
      #Dry Refraction (Vietnam)
      opdrecord.dry_refraction_advice = nil
  
      #PMT Refraction (Vietnam)
      opdrecord.perform_pmt = nil
  
      #PMT Refraction
      opdrecord.pmt_refraction_advice = nil
  
      #Dilated Net Retinoscopy (Vietnam)
      opdrecord.dilate_patient = nil
      opdrecord.dilated_refraction_advice = nil
      return opdrecord
    end

    def self.unset_vital_signs(opdrecord)
      opdrecord.vital_signs_temperature = nil
      opdrecord.vital_signs_pulse = nil
      opdrecord.vital_signs_bp = nil
      opdrecord.vital_signs_rr = nil
      opdrecord.vital_signs_spo2 = nil
      return opdrecord
    end

    def self.unset_medications(opdrecord)
      opdrecord.treatmentmedication = nil
      opdrecord.view_pharmacy_store_id = nil
      opdrecord.pharmacy_store_id = nil
      opdrecord.no_medications_advised = nil
      return opdrecord
    end

  end
end
