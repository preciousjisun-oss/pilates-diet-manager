# Supabase 연결 가이드

이 문서는 정적 HTML 앱을 실제 웹앱으로 발전시키기 위한 다음 단계입니다.

## 1. Supabase 프로젝트 생성

1. https://supabase.com 접속
2. 새 프로젝트 생성
3. 프로젝트 이름: `pilates-diet-manager`
4. 비밀번호 설정
5. 생성 완료 후 프로젝트 대시보드 접속

## 2. SQL 실행

Supabase SQL Editor에서 다음 파일의 내용을 실행하세요:

- `supabase-schema.sql`

이렇게 하면 다음 테이블이 생성됩니다.

- `profiles`
- `meals`
- `exercises`

## 3. 프로젝트 환경 변수 준비

프로젝트 > Settings > API 에서 다음 값을 복사합니다.

- Project URL
- anon public key
- service role key (백엔드에서만 사용)

## 4. 브라우저에 연결할 코드

브라우저에서 사용할 때는 다음 패턴입니다.

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script>
  const supabase = window.supabase.createClient(
    'https://YOUR-PROJECT-ID.supabase.co',
    'YOUR-ANON-KEY'
  );

  async function signUp(email, password, displayName) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName }
      }
    });

    if (error) throw error;
    return data;
  }

  async function signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  }
</script>
```

## 5. 사용자별 데이터 저장 예시

```javascript
async function saveMeal(mealDate, name, calories, carbs, protein, fat) {
  const { data: { user } } = await supabase.auth.getUser();

  const { data, error } = await supabase
    .from('meals')
    .insert([
      {
        user_id: user.id,
        meal_date: mealDate,
        name,
        calories,
        carbs,
        protein,
        fat
      }
    ]);

  if (error) throw error;
  return data;
}
```

## 6. 실제 로그인 기능 구현 방식

브라우저 정적 HTML만으로는 안전한 로그인/회원 기능을 완성할 수 없습니다. 반드시 Supabase Auth를 사용해야 합니다.

다음 단계는 다음 구조가 됩니다.

- 가입/로그인 화면
- 사용자별 프로필 저장
- 식단/운동 데이터 저장
- AI 이미지 인식 API 연결
- 마이페이지에서 이름/목표 수정

## 7. 다음 구현 단계

다음 단계로는 아래 순서를 추천합니다.

1. 로그인/회원가입 화면 추가
2. `profiles` 테이블에서 사용자 이름 불러오기
3. `meals`, `exercises` 관련 CRUD 연결
4. OpenAI 또는 Gemini API 연결
5. GitHub Pages 정적 앱에서 Supabase 연동 앱으로 전환

## 8. 실제 서비스 환경

정적 HTML 페이지는 보안상 API 키를 클라이언트에 넣을 수 없습니다. 따라서 실제 AI 분석은 다음 구조가 안전합니다.

- 브라우저에서 이미지 업로드
- Supabase Edge Function으로 이미지 전송
- 서버에서 OpenAI/Gemini API 호출
- 결과를 다시 브라우저로 전달

이 구조가 가장 안전합니다.

## 9. 추천 도구

- Frontend: HTML + JavaScript or Next.js
- Auth: Supabase Auth
- Database: Supabase Postgres
- AI: OpenAI Vision / Google Gemini
- Deployment: Vercel 또는 GitHub Pages + Supabase (정적 파일은 제한적)

## 10. 다음 실전 작업

다음 커밋 단계는 다음 중 하나입니다.

- 1) 실제 로그인을 붙이는 버전
- 2) Supabase + AI 이미지 분석 통합 버전
- 3) Next.js로 재구성한 완전 앱 버전

원하시면 다음 단계로 실제 코드까지 바로 이어서 만들어 드립니다.
