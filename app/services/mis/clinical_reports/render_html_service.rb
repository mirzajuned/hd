module Mis::ClinicalReports
  class RenderHtmlService
    class << self
      def visit_html(vist)
        r_visualacuity_unaided = vist.r_visualacuity_unaided
        r_visualacuity_ua_near = vist.r_visualacuity_ua_near
        r_visualacuity_ua_s = vist.r_visualacuity_ua_s
        r_visualacuity_ua_i = vist.r_visualacuity_ua_i
        r_visualacuity_ua_n = vist.r_visualacuity_ua_n
        r_visualacuity_ua_t = vist.r_visualacuity_ua_t
        l_visualacuity_ua_near = vist.l_visualacuity_ua_near
        l_visualacuity_unaided = vist.l_visualacuity_unaided
        l_visualacuity_ua_s = vist.l_visualacuity_ua_s
        l_visualacuity_ua_i = vist.l_visualacuity_ua_i
        l_visualacuity_ua_n = vist.l_visualacuity_ua_n
        l_visualacuity_ua_t = vist.l_visualacuity_ua_t
        r_visualacuity_pinhole = vist.r_visualacuity_pinhole
        r_visualacuity_glasses = vist.r_visualacuity_glasses
        r_visualacuity_near = vist.r_visualacuity_near
        l_visualacuity_pinhole = vist.l_visualacuity_pinhole
        l_visualacuity_glasses = vist.l_visualacuity_glasses
        l_visualacuity_near = vist.l_visualacuity_near

        pr_ua_l = if l_visualacuity_ua_s.present? || l_visualacuity_ua_i.present? || l_visualacuity_ua_n.present? || l_visualacuity_ua_t.present?
                    "PR(UA): #{l_visualacuity_ua_s}#{l_visualacuity_ua_i}#{l_visualacuity_ua_n}#{l_visualacuity_ua_t}"
                  else
                    ' '
                  end
        pr_ua_r = if r_visualacuity_ua_s.present? || r_visualacuity_ua_i.present? || r_visualacuity_ua_n.present? || r_visualacuity_ua_t.present?
                    "PR(UA): #{r_visualacuity_ua_s}#{r_visualacuity_ua_i}#{r_visualacuity_ua_n}#{r_visualacuity_ua_t}"
                  else
                    ' '
                  end

        html_value = "<table class='table table-bordered'>
        <thead>
        <tr>
        <th></th>
        <th>Right Eye</th>
        <th>Left Eye</th>
      </tr>
        </thead>
      <tbody>

          <tr>
            <td><b>UVA</b></td>
            <td><b>
              #{r_visualacuity_unaided} #{r_visualacuity_ua_near}
        #{pr_ua_r}
            </b></td>
            <td><b>
              #{l_visualacuity_unaided} #{l_visualacuity_ua_near}
        #{pr_ua_l}
            </b></td>
          </tr>
        <tr>
        <td><b>BCVA</b></td>
        <td><b>
        #{r_visualacuity_pinhole} #{r_visualacuity_glasses} #{r_visualacuity_near}
            </b></td>
            <td><b>
              #{l_visualacuity_pinhole} #{l_visualacuity_glasses} #{l_visualacuity_near}
        </b></td>
        </tr>
    </tbody>
    </table>"

        html_value.html_safe
      end
    end
  end
end
